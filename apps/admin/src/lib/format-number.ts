export function compactFormat(value: number | string): string {
  const num = typeof value === "string" ? parseFloat(value) : value;
  
  if (isNaN(num)) {
    return "0";
  }

  return new Intl.NumberFormat("en-US", {
    notation: "compact",
    compactDisplay: "short",
    maximumFractionDigits: 1,
  }).format(num);
}

/**
 * Fallback for template components expecting standardFormat
 */
export function standardFormat(value: number | string): string {
  return compactFormat(value);
}