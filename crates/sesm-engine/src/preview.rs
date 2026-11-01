use crate::{analyze, MAX_PIXELS, MAX_SVG};
use base64::{engine::general_purpose::STANDARD, Engine};
use resvg::{tiny_skia, usvg};
use std::{
    io::Cursor,
    sync::{Arc, Mutex},
};

pub fn render(bytes: &[u8]) -> Result<String, String> {
    let analysis = analyze(bytes);
    if analysis.findings.iter().any(|f| f.severity == "error") {
        return Err("Preview unavailable for malformed or forbidden SVG content.".into());
    }
    let raster_error = Arc::new(Mutex::new(None::<String>));
    let resolver_error = raster_error.clone();
    let mut options = usvg::Options {
        resources_dir: None,
        image_href_resolver: usvg::ImageHrefResolver {
            resolve_string: Box::new(|_, _| None),
            resolve_data: Box::new(move |mime, data, opts| {
                let resolve = || -> Result<usvg::ImageKind, String> {
                    if data.len() > MAX_SVG
                        || ![
                            "image/png",
                            "image/jpeg",
                            "image/jpg",
                            "image/gif",
                            "image/webp",
                        ]
                        .contains(&mime)
                    {
                        return Err("Embedded raster type or byte size is unsupported.".into());
                    }
                    let reader = image::ImageReader::new(Cursor::new(data.as_ref()))
                        .with_guessed_format()
                        .map_err(|e| format!("Embedded raster format: {e}"))?;
                    let (width, height) = reader
                        .into_dimensions()
                        .map_err(|e| format!("Embedded raster dimensions: {e}"))?;
                    if u64::from(width) * u64::from(height) > MAX_PIXELS {
                        return Err("Embedded raster exceeds the 16 megapixel limit.".into());
                    }
                    (usvg::ImageHrefResolver::default_data_resolver())(mime, data, opts)
                        .ok_or_else(|| "Embedded raster could not be decoded.".into())
                };
                match resolve() {
                    Ok(image) => Some(image),
                    Err(e) => {
                        if let Ok(mut error) = resolver_error.lock() {
                            *error = Some(e);
                        }
                        None
                    }
                }
            }),
        },
        ..Default::default()
    };
    // Bundled/system font faces contain no SVG-controlled paths. External image URLs are disabled above.
    options.fontdb_mut().load_system_fonts();
    let tree = usvg::Tree::from_data(bytes, &options).map_err(|e| format!("SVG renderer: {e}"))?;
    if let Some(error) = raster_error
        .lock()
        .map_err(|_| "Raster preview lock failed.")?
        .take()
    {
        return Err(error);
    }
    let size = tree.size().to_int_size();
    if u64::from(size.width()) * u64::from(size.height()) > MAX_PIXELS {
        return Err("Preview exceeds 16 megapixels; SVG bytes remain unchanged.".into());
    }
    let mut pixmap =
        tiny_skia::Pixmap::new(size.width(), size.height()).ok_or("Could not allocate preview.")?;
    resvg::render(&tree, tiny_skia::Transform::default(), &mut pixmap.as_mut());
    let png = pixmap.encode_png().map_err(|e| e.to_string())?;
    Ok(format!("data:image/png;base64,{}", STANDARD.encode(png)))
}
