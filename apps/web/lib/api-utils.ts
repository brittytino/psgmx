/**
 * Safely parses the JSON response from a fetch call.
 * If the response is not valid JSON (e.g., an HTML error page), it returns a user-friendly error message.
 * @param res The fetch Response object.
 * @returns The parsed JSON data or an object with an error message.
 */
export async function safeParseJson<T>(res: Response): Promise<T | { error: string }> {
  try {
    const text = await res.text();
    if (!text) {
      return { error: 'Empty response from server.' };
    }
    
    try {
      return JSON.parse(text) as T;
    } catch (e) {
      // If parsing fails, it's likely not JSON (HTML error page, etc.)
      console.error('[API Utils] Failed to parse JSON:', e, 'Response text:', text.substring(0, 100));
      return { error: 'The server returned an unexpected response. Please try again later.' };
    }
  } catch (e) {
    console.error('[API Utils] Failed to read response text:', e);
    return { error: 'Failed to read the server response.' };
  }
}
