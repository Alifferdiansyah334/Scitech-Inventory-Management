export function buildPreviewUrl(bucket: string, fileId: string) {
  return `/api/images/${encodeURIComponent(fileId)}?bucket=${encodeURIComponent(bucket)}`;
}
