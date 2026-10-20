/**
 * Normalizes string by removing accents and converting to lowercase.
 * Useful for case-insensitive and accent-insensitive searching.
 */
export function normalizeString(str: string): string {
  if (!str) return '';
  return str
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim();
}

/**
 * Creates URL-friendly slug from string.
 */
export function slugify(str: string): string {
  if (!str) return '';
  return normalizeString(str)
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-+|-+$/g, '');
}
