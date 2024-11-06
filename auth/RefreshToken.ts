import { Router } from "expo-router";
import { ApiUrl } from "./ApiUrl";
import { getToken, saveToken } from "@/auth/SecureStore";
import axios, { AxiosError } from "axios";

export async function refreshAccessToken(): Promise<{
  refreshTokenValid: boolean;
}> {
  const refreshToken = await getToken("refreshToken");

  try {
    const res = await axios.post(`${ApiUrl}/api/auth/refresh-token`, {
      token: refreshToken,
    });
    const { accessToken, refreshToken: newRefreshToken } = res.data;
    // Save the new tokens
    await saveToken("accessToken", accessToken);
    await saveToken("refreshToken", newRefreshToken);
    return { refreshTokenValid: true };
  } catch (err) {
    const error = err as AxiosError;
    console.log(`${error}`);
    return { refreshTokenValid: false };
  }
}
