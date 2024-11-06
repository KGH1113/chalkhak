const url = process.env.EXPO_PUBLIC_API_URL;
if (!url) {
  console.error("No API URL");
}
export const ApiUrl = url;
