
/**
 * Formats a date or date string into a clean, human-readable time for chat modules
 *
 * e.g., "10:42 AM", "Yesterday", or "Monday"
 */
export function formatMessageTime(dateInput: string | Date | number): string {
const date = new Date(dateInput);

if (isNaN(date.getTime())) {
return "";
}

const now = new Date();

// Reset hours to compare calendar days accurately
const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
const compareDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());

const diffTime = today.getTime() - compareDate.getTime();
const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

if (diffDays === 0) {
// Today: return time (e.g., "10:42 AM")
return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
} else if (diffDays === 1) {
// Yesterday
return "Yesterday";
} else if (diffDays < 7) {
// Within this week: return day name (e.g., "Monday")
return date.toLocaleDateString([], { weekday: "long" });
} else {
// Older: return date (e.g., "Jun 23")
return date.toLocaleDateString([], { month: "short", day: "numeric" });
}
}