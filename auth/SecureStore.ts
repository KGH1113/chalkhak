import * as SecureStore from "expo-secure-store";

// Save token
export async function saveToken(key: string, value: string): Promise<void> {
  await SecureStore.setItemAsync(key, value);
}

// Get token
export async function getToken(key: string): Promise<string> {
  const token = await SecureStore.getItemAsync(key);
  if (!token) {
    return "";
  }
  return token;
}

// Delete token
export async function deleteToken(key: string): Promise<void> {
  await SecureStore.setItemAsync(key, "");
}