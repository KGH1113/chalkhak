import { useState, useEffect } from "react";
import axios from "axios";
import { router } from "expo-router";
import { ApiUrl } from "@/auth/ApiUrl";
import { AxiosError } from "axios";
import { getToken, saveToken } from "@/auth/SecureStore";
import { Spinner } from "@/components/ui/spinner";
import { VStack } from "@/components/ui/vstack";
import { refreshAccessToken } from "@/auth/RefreshToken";

const indexPage = () => {
  useEffect(() => {
    (async () => {
      try {
        const accessToken = await getToken("accessToken");
        if (!accessToken) {
          const { refreshTokenValid } = await refreshAccessToken();
          if (!refreshTokenValid) {
            router.push("/auth/splash-screen");
          }
        }
        const res = await axios.get(`${ApiUrl}/api/auth/protected/`, {
          headers: {
            Authorization: "Bearer " + accessToken,
          },
        });
        await saveToken("userId", res.data.user.userId);
        console.log(res.data);
        router.push("/main");
      } catch (err) {
        const error = err as AxiosError;
        if (error.status === 401 || error.status === 403) {
          const { refreshTokenValid } = await refreshAccessToken();
          if (!refreshTokenValid) {
            router.push("/auth/splash-screen");
          }
        } else {
          console.log(error);
        }
      }
    })();
  }, []);

  return (
    <VStack className="h-full w-full items-center justify-center">
      <Spinner />
    </VStack>
  );
};

export default indexPage;
