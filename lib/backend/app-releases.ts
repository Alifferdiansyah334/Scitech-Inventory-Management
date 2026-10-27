export const maxApkBytes = 150 * 1024 * 1024;
export type AndroidRelease = { version: string; build_number: number; apk_path: string; sha256: string; size_bytes: number; notes: string };

export function parseAndroidRelease(input: unknown): AndroidRelease {
  if (!input || typeof input !== 'object') throw new Error('Invalid release');
  const data = input as Record<string, unknown>;
  if (typeof data.version !== 'string' || !/^\d+\.\d+\.\d+$/.test(data.version)
    || !Number.isSafeInteger(data.build_number) || Number(data.build_number) < 1
    || typeof data.apk_path !== 'string' || !/^\/releases\/[A-Za-z0-9][A-Za-z0-9._+-]*\.apk$/.test(data.apk_path)
    || typeof data.sha256 !== 'string' || !/^[a-f0-9]{64}$/.test(data.sha256)
    || !Number.isSafeInteger(data.size_bytes) || Number(data.size_bytes) < 1 || Number(data.size_bytes) > maxApkBytes
    || (data.notes !== undefined && (typeof data.notes !== 'string' || data.notes.length > 2000))) throw new Error('Invalid release');
  return { version:data.version, build_number:Number(data.build_number), apk_path:data.apk_path, sha256:data.sha256, size_bytes:Number(data.size_bytes), notes:typeof data.notes === 'string' ? data.notes : '' };
}
