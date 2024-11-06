import { VStack } from "@/components/ui/vstack";
import { Button, ButtonText } from "@/components/ui/button";
import { Icon } from "@/components/ui/icon";
import { useColorScheme } from "nativewind";

import { useRouter } from "expo-router";
import { AuthLayout } from "@/components/AuthLayout";
import { Heading } from "@/components/ui/heading";

const SplashScreenUI = () => {
  const router = useRouter();
  const { colorScheme } = useColorScheme();
  return (
    <VStack
      className="w-full max-w-[440px] items-center h-full justify-center"
      space="lg"
    >
      <Heading size="2xl">Welcome to Chalkhak</Heading>
      <VStack className="w-full" space="lg">
        <Button
          className="w-full"
          onPress={() => {
            router.push("/auth/signin");
          }}
        >
          <ButtonText className="font-medium">Log in</ButtonText>
        </Button>
        <Button
          onPress={() => {
            router.push("/auth/register");
          }}
        >
          <ButtonText className="font-medium">Sign Up</ButtonText>
        </Button>
      </VStack>
    </VStack>
  );
};

const SplashScreen = () => {
  return (
    <AuthLayout>
      <SplashScreenUI />
    </AuthLayout>
  );
};

export default SplashScreen;
