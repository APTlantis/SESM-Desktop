import { invoke } from '@tauri-apps/api/core';
export const isDesktop = () => '__TAURI_INTERNALS__' in window;
export async function call<T>(command: string, args?: Record<string, unknown>): Promise<T> {
  if (!isDesktop()) throw new Error('Open the desktop application to select and process local SVG files.');
  return invoke<T>(command, args);
}
