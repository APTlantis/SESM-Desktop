use crate::{Finding, MAX_SVG};
use quick_xml::{events::Event, Reader};
use roxmltree::Document;
use serde::Serialize;
use std::{ops::Range, sync::LazyLock};

#[derive(Clone, Debug, Serialize)]
pub struct Observation {
    pub property: String,
    pub value: String,
    pub source: String,
}
#[derive(Clone, Default)]
pub struct Analysis {
    pub metadata_text: Option<String>,
    pub metadata_range: Option<Range<usize>>,
    pub insertion: Option<(usize, bool)>,
    pub prefix: String,
    pub findings: Vec<Finding>,
    pub observations: Vec<Observation>,
}
fn error(result: &mut Analysis, code: &str, message: impl Into<String>) {
    result
        .findings
        .push(Finding::new("xml", "error", code, message, "/svg"));
}
pub fn analyze(bytes: &[u8]) -> Analysis {
    let mut result = Analysis::default();
    if bytes.len() > MAX_SVG {
        error(&mut result, "svg-size", "SVG exceeds the 5 MiB limit.");
        return result;
    }
    let Ok(text) = std::str::from_utf8(bytes) else {
        error(
            &mut result,
            "encoding",
            "Only UTF-8 SVGs are supported; original bytes have not been changed.",
        );
        return result;
    };
    let mut reader = Reader::from_str(text);
    let mut depth = 0;
    loop {
        match reader.read_event() {
            Ok(Event::DocType(_)) => {
                error(
                    &mut result,
                    "doctype",
                    "DTDs and external entities are not supported.",
                );
                return result;
            }
            Ok(Event::Decl(d)) => {
                if let Some(enc) = d.encoding() {
                    match enc {
                        Ok(e) if e.eq_ignore_ascii_case(b"UTF-8") => {}
                        _ => {
                            error(
                                &mut result,
                                "encoding",
                                "XML declares an unsupported encoding.",
                            );
                            return result;
                        }
                    }
                }
            }
            Ok(Event::Start(_)) => {
                depth += 1;
                if depth > 128 {
                    error(&mut result, "xml-depth", "XML nesting exceeds 128 levels.");
                    return result;
                }
            }
            Ok(Event::End(_)) => {
                depth -= 1;
            }
            Ok(Event::Eof) => break,
            Err(e) => {
                error(&mut result, "xml-parse", e.to_string());
                return result;
            }
            _ => {}
        }
    }
    let parsed = match Document::parse(text) {
        Ok(d) => d,
        Err(e) => {
            error(&mut result, "xml-parse", e.to_string());
            return result;
        }
    };
    let root = parsed.root_element();
    let ns = root.tag_name().namespace();
    if root.tag_name().name() != "svg" || (ns.is_some() && ns != Some("http://www.w3.org/2000/svg"))
    {
        error(&mut result, "svg-root", "Root element must be SVG.");
        return result;
    }
    // Locate the root start tag with XML quoting respected; offsets refer to original UTF-8 bytes.
    let start = root.range().start;
    let mut quote = None;
    let mut end = None;
    for (offset, b) in text.as_bytes()[start..].iter().copied().enumerate() {
        if let Some(q) = quote {
            if b == q {
                quote = None;
            }
        } else if b == b'\'' || b == b'"' {
            quote = Some(b);
        } else if b == b'>' {
            end = Some(start + offset);
            break;
        }
    }
    if let Some(end) = end {
        let qname = text[start + 1..]
            .split(|c: char| c.is_whitespace() || c == '/' || c == '>')
            .next()
            .unwrap_or("svg");
        result.prefix = qname
            .rsplit_once(':')
            .map(|(p, _)| format!("{p}:"))
            .unwrap_or_default();
        result.insertion = Some(if bytes[end - 1] == b'/' {
            (end - 1, true)
        } else {
            (end + 1, false)
        });
    }
    for prop in ["width", "height", "viewBox"] {
        if let Some(v) = root.attribute(prop) {
            result.observations.push(Observation {
                property: prop.into(),
                value: v.into(),
                source: format!("/svg/@{prop}"),
            });
        }
    }
    let mut blocks = Vec::new();
    for node in root.descendants().filter(|n| n.is_element()) {
        let name = node.tag_name().name();
        let path = format!("/svg/{}@byte:{}", name, node.range().start);
        if name == "metadata" && node.attribute("id") == Some("sesm") {
            if node.tag_name().namespace() != ns {
                result.findings.push(Finding::new(
                    "xml",
                    "error",
                    "metadata-namespace",
                    "SESM block must use the SVG namespace.",
                    &path,
                ));
            }
            blocks.push(node);
        }
        if ["script", "foreignObject", "iframe", "object", "embed"]
            .iter()
            .any(|n| name.eq_ignore_ascii_case(n))
        {
            result.findings.push(Finding::new(
                "safety",
                "error",
                "active-element",
                format!("Active or unsupported executable element: {name}."),
                &path,
            ));
        }
        if ["title", "desc", "text"].contains(&name) {
            let value: String = node
                .descendants()
                .filter(|n| n.is_text())
                .filter_map(|n| n.text())
                .collect();
            if !value.trim().is_empty() {
                result.observations.push(Observation {
                    property: name.into(),
                    value: value.chars().take(2048).collect(),
                    source: path.clone(),
                });
            }
            if name == "text"
                && (node.attribute("display") == Some("none")
                    || node.attribute("visibility") == Some("hidden")
                    || node.attribute("opacity") == Some("0")
                    || node.attribute("font-size") == Some("0")
                    || node.attribute("style").is_some_and(|s| {
                        s.contains("display:none")
                            || s.contains("display: none")
                            || s.contains("opacity:0")
                            || s.contains("font-size:0")
                    }))
            {
                result.findings.push(Finding::new(
                    "safety",
                    "warning",
                    "hidden-text",
                    "Hidden text requires review.",
                    &path,
                ));
            }
        }
        for attribute in node.attributes() {
            let name = attribute.name().to_ascii_lowercase();
            let value = attribute.value();
            let loc = format!("{path}/@{name}");
            let normalized: String = value
                .chars()
                .filter(|c| !c.is_whitespace() && !c.is_control())
                .flat_map(char::to_lowercase)
                .collect();
            if name.starts_with("on")
                || normalized.contains("javascript:")
                || normalized.contains("vbscript:")
            {
                result.findings.push(Finding::new(
                    "safety",
                    "error",
                    "executable-attribute",
                    "Event handlers and executable URLs are forbidden.",
                    &loc,
                ));
            }
            if name == "href" && !value.starts_with('#') && !value.is_empty() {
                if normalized.starts_with("data:") {
                    if ![
                        "data:image/png;base64,",
                        "data:image/jpeg;base64,",
                        "data:image/jpg;base64,",
                        "data:image/gif;base64,",
                        "data:image/webp;base64,",
                    ]
                    .iter()
                    .any(|p| normalized.starts_with(p))
                    {
                        result.findings.push(Finding::new(
                            "safety",
                            "error",
                            "embedded-payload",
                            "Only embedded PNG, JPEG, GIF and WebP raster images are supported.",
                            &loc,
                        ));
                    } else {
                        result.findings.push(Finding::new(
                            "safety",
                            "warning",
                            "embedded-raster",
                            "Embedded raster data requires review; previews enforce image limits.",
                            &loc,
                        ));
                    }
                } else {
                    result.findings.push(Finding::new(
                        "safety",
                        "warning",
                        "external-reference",
                        "External references are preserved but never fetched for previews.",
                        &loc,
                    ));
                }
            }
            if ["fill", "stroke", "color", "stop-color", "flood-color"].contains(&name.as_str()) {
                result.observations.push(Observation {
                    property: "declared-color".into(),
                    value: value.into(),
                    source: loc.clone(),
                });
            }
            if name == "style" || normalized.contains("url(") {
                inspect_css(value, &loc, &mut result.findings);
            }
        }
        if name == "style" {
            let css: String = node.children().filter_map(|n| n.text()).collect();
            inspect_css(&css, &path, &mut result.findings);
            static COLOR: LazyLock<regex::Regex> = LazyLock::new(|| {
                regex::Regex::new(r"(?i)(?:fill|stroke|color|stop-color)\s*:\s*([^;}]+)").unwrap()
            });
            for capture in COLOR.captures_iter(&css) {
                result.observations.push(Observation {
                    property: "declared-color".into(),
                    value: capture[1].trim().into(),
                    source: path.clone(),
                });
            }
        }
    }
    for node in parsed.descendants() {
        if node.is_pi() {
            result.findings.push(Finding::new(
                "safety",
                "warning",
                "processing-instruction",
                "XML processing instructions are preserved but not executed.",
                format!("byte:{}", node.range().start),
            ));
        }
        if node.is_comment() && node.text().unwrap_or("").len() > 8192 {
            result.findings.push(Finding::new(
                "safety",
                "warning",
                "large-comment",
                "Large comment requires payload review.",
                format!("byte:{}", node.range().start),
            ));
        }
    }
    if blocks.len() > 1 {
        error(
            &mut result,
            "sesm-duplicate",
            "Multiple SESM blocks are ambiguous; repair outside this tool before export.",
        );
    } else if let Some(block) = blocks.first() {
        result.metadata_range = Some(block.range());
        if block.children().any(|n| n.is_element()) {
            error(
                &mut result,
                "metadata-xml",
                "SESM must contain JSON text, not child XML elements.",
            );
        }
        result.metadata_text = Some(
            block
                .children()
                .filter(|n| n.is_text())
                .filter_map(|n| n.text())
                .collect(),
        );
    }
    result.observations.truncate(500);
    result
}

fn inspect_css(css: &str, path: &str, findings: &mut Vec<Finding>) {
    let compact: String = css
        .chars()
        .filter(|c| !c.is_whitespace() && !c.is_control())
        .flat_map(char::to_lowercase)
        .collect();
    if compact.contains("javascript:")
        || compact.contains("expression(")
        || compact.contains("-moz-binding")
        || compact.contains("behavior:")
    {
        findings.push(Finding::new(
            "safety",
            "error",
            "executable-css",
            "Executable CSS is forbidden.",
            path,
        ));
    }
    if compact.contains("@import") || compact.contains("url(") || compact.contains('\\') {
        // Conservative: even local paint URLs remain review warnings; never claim a clean safe profile without review.
        findings.push(Finding::new(
            "safety",
            "warning",
            "css-resource",
            "CSS resource references or escapes require review; external resources are not loaded.",
            path,
        ));
    }
}
