import { useState, useEffect, useRef } from "react";

import MapUI from "@/components/MapUI";

import {
  StyleSheet,
  View,
  Platform,
  TextInput,
  KeyboardAvoidingView,
  ScrollView,
  Dimensions,
} from "react-native";

import {
  Plus,
  ArrowLeft,
  ArrowRight,
  Upload,
  Key,
  User as UserIcon,
  Edit,
  LogOut,
  User,
} from "lucide-react-native";

import { Button, ButtonIcon, ButtonText } from "@/components/ui/button";
import {
  Drawer,
  DrawerBackdrop,
  DrawerBody,
  DrawerContent,
  DrawerHeader,
  DrawerFooter,
} from "@/components/ui/drawer";
import {
  Avatar,
  AvatarBadge,
  AvatarFallbackText,
  AvatarImage,
} from "@/components/ui/avatar";
import { Heading } from "@/components/ui/heading";
import { Text } from "@/components/ui/text";
import { Fab, FabIcon, FabLabel } from "@/components/ui/fab";
import { Box } from "@/components/ui/box";
import { Pressable } from "@/components/ui/pressable";
import { Textarea, TextareaInput } from "@/components/ui/textarea";
import { Keyboard, Image } from "react-native";
import { Center } from "@/components/ui/center";
import { VStack } from "@/components/ui/vstack";
import { HStack } from "@/components/ui/hstack";
import { Toast, ToastTitle, useToast } from "@/components/ui/toast";
import {
  FormControl,
  FormControlError,
  FormControlErrorIcon,
  FormControlErrorText,
  FormControlLabel,
  FormControlLabelText,
} from "@/components/ui/form-control";

import {
  SafeAreaProvider,
  useSafeAreaInsets,
} from "react-native-safe-area-context";
import { SafeAreaView } from "@/components/ui/safe-area-view";
import * as ImagePicker from "expo-image-picker";
import * as FileSystem from "expo-file-system";
import Mime from "mime";

import axios from "axios";

import { saveToken, getToken, deleteToken } from "@/auth/SecureStore";
import { refreshAccessToken } from "@/auth/RefreshToken";
import { ApiUrl } from "@/auth/ApiUrl";

import { groupSimilarPosts } from "@/utils/ProcessCoords";

import { router } from "expo-router";

import * as Location from "expo-location";
import { Icon } from "@/components/ui/icon";
import {
  Modal,
  ModalBackdrop,
  ModalBody,
  ModalCloseButton,
  ModalContent,
  ModalFooter,
  ModalHeader,
} from "@/components/ui/modal";
import { Input, InputField } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";

// import * as Device from "expo-device";

const FormData = global.FormData;

interface Post {
  postId: string;
  userId: string;
  content: string;
  mediaUrl: string;
  latitude: number;
  longitude: number;
  createdAt: Date;
  hidden: boolean;
}

interface User {
  userId: string;
  username: string;
  email: string;
  createdAt: Date;
  fullName?: string;
  bio?: string;
  profilePictureUrl?: string;
  isPrivate: boolean;
}

export default function MainScreen() {
  const [showAddPostDrawer, setShowAddPostDrawer] = useState<boolean>(false);
  const [showProfileDrawer, setShowProfileDrawer] = useState<boolean>(false);
  const [showEditProfileModal, setShowEditProfileModal] =
    useState<boolean>(false);
  const [showFollowersModal, setShowFollowersModal] = useState<boolean>(false);
  const [showFollowingsModal, setShowFollowingsModal] =
    useState<boolean>(false);
  const [showAddFollowingModal, setShowAddFollowingModal] =
    useState<boolean>(false);

  const [imageUri, setImageUri] = useState<string>();
  const [posts, setPosts] = useState<Post[]>([]);
  const [date, setDate] = useState<string>("");

  const [content, setContent] = useState<string>("");
  const [mediaUrl, setMediaUrl] = useState<string>("");

  const [editedProfileImageUri, setEditedProfileImageUri] =
    useState<string>("");
  const [editedProfileMediaUrl, setEditedProfileMediaUrl] =
    useState<string>("");
  const [editedBio, setEditedBio] = useState<string>("");
  const [editedPassword, setEditedPassword] = useState<string>("");
  const [editedFullName, setEditedFullName] = useState<string>("");
  const [editedIsPrivate, setEditedIsPrivate] = useState<boolean>(true);

  const [appUser, setAppUser] = useState<User>();
  const [appUserFollowers, setAppUserFollowers] = useState<
    {
      userId: string;
      username: string;
      fullName: string;
      profilePicUrl: string;
    }[]
  >([]);
  const [appUserFollowings, setAppUserFollowings] = useState<
    {
      userId: string;
      username: string;
      fullName: string;
      profilePicUrl: string;
    }[]
  >([]);

  const insets = useSafeAreaInsets();
  const toast = useToast();

  function closeOverlays() {
    setShowAddPostDrawer(false);
    setShowProfileDrawer(false);
    setShowEditProfileModal(false);
    setShowFollowersModal(false);
    setShowFollowingsModal(false);
    setShowAddFollowingModal(false);
  }

  useEffect(() => {
    const interval = setInterval(async () => {
      await getPosts();
    }, 10000);

    (async () => {
      await getAppUser();

      const libaryStatus =
        await ImagePicker.requestMediaLibraryPermissionsAsync();
      if (libaryStatus.status !== "granted") {
        return;
      }

      const cameraStatus = await ImagePicker.requestCameraPermissionsAsync();
      if (cameraStatus.status !== "granted") {
        return;
      }

      await getPosts();
    })();
    // console.log(
    //   `${Device.manufacturer}, ${Device.modelName}, ${[insets.top, insets.bottom, insets.left, insets.right]}`
    // );

    return () => {
      closeOverlays();
      clearInterval(interval);
    };
  }, []);

  useEffect(() => {
    (async () => {
      await getPosts(!date ? null : date);
    })();
  }, [date]);

  async function getPosts(date?: string): Promise<void> {
    try {
      const url = !date
        ? `${ApiUrl}/api/posts/get`
        : `${ApiUrl}/api/posts/get?date=${date}`;
      const res = await axios.get(url, {
        headers: {
          Authorization: "Bearer " + (await getToken("accessToken")),
        },
      });
      const postsData = res.data;
      if (postsData.length !== posts.length) {
        setPosts(postsData);
      }
    } catch (err) {
      console.log(err);
      if (err.status === 403) {
        const { refreshTokenValid } = await refreshAccessToken();
        if (!refreshTokenValid) {
          closeOverlays();
          router.push("/auth/splash-screen");
        }
      }
    }
  }

  async function getAppUser(): Promise<void> {
    const appUserId = await getToken("userId");
    try {
      const { data: appUserData }: { data: User } = await axios.post(
        `${ApiUrl}/api/users/get`,
        { userId: appUserId },
        {
          headers: {
            Authorization: "Bearer " + (await getToken("accessToken")),
          },
        }
      );
      appUserData.createdAt = new Date(appUserData.createdAt);
      setAppUser(appUserData);
      await axios.post(`${ApiUrl}/api/`)
    } catch (err) {
      console.log(err);
      if (err.status === 403) {
        const { refreshTokenValid } = await refreshAccessToken();
        if (!refreshTokenValid) {
          closeOverlays();
          router.push("/auth/splash-screen");
        }
      }
    }
  }

  async function pickImage(): Promise<void> {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.All,
      allowsEditing: true,
      aspect: [4, 3],
      quality: 1,
    });

    if (!result.canceled) {
      const selectedImageUri = result.assets[0].uri;
      console.log(selectedImageUri);
      setImageUri(selectedImageUri);

      const formData = new FormData();
      const mimeType =
        Mime.getType(selectedImageUri) || "application/octet-stream";
      formData.append("file", {
        uri: selectedImageUri,
        name: selectedImageUri.split("/").pop(),
        type: mimeType,
      } as any);

      try {
        const acessToken = await getToken("accessToken");
        if (!acessToken) {
          return;
        }

        const res = await axios.post(
          `${ApiUrl}/api/posts/upload-media/`,
          formData,
          {
            headers: {
              Authorization: "Bearer " + (await getToken("accessToken")),
              "Content-Type": "multipart/form-data",
            },
          }
        );
        setMediaUrl(res.data.fileUrl);
        console.log(mediaUrl);
      } catch (err) {
        console.log(err);
        if (err.status === 403) {
          const { refreshTokenValid } = await refreshAccessToken();
          if (!refreshTokenValid) {
            closeOverlays();
            router.push("/auth/splash-screen");
          }
        }
      }
    }
  }

  async function pickProfileImage(): Promise<void> {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.All,
      allowsEditing: true,
      aspect: [4, 3],
      quality: 1,
    });

    if (!result.canceled) {
      const selectedImageUri = result.assets[0].uri;
      setEditedProfileImageUri(selectedImageUri);
      let editedMediaUrlData = "";

      const formData = new FormData();
      const mimeType =
        Mime.getType(selectedImageUri) || "application/octet-stream";
      formData.append("file", {
        uri: selectedImageUri,
        name: selectedImageUri.split("/").pop(),
        type: mimeType,
      } as any);

      try {
        const acessToken = await getToken("accessToken");
        if (!acessToken) {
          return;
        }

        const res = await axios.post(
          `${ApiUrl}/api/posts/upload-media/`,
          formData,
          {
            headers: {
              Authorization: "Bearer " + (await getToken("accessToken")),
              "Content-Type": "multipart/form-data",
            },
          }
        );
        editedMediaUrlData = res.data.fileUrl;
        setEditedProfileMediaUrl(editedMediaUrlData);
      } catch (err) {
        console.log(err);
        if (err.status === 403) {
          const { refreshTokenValid } = await refreshAccessToken();
          if (!refreshTokenValid) {
            closeOverlays();
          }
        }
      }

      try {
        await axios.put(
          `${ApiUrl}/api/users/edit`,
          {
            username: appUser.username,
            email: appUser.email,
            password: "",
            fullName: appUser.fullName,
            bio: appUser.bio,
            profilePictureUrl: editedMediaUrlData,
            isPrivate: appUser.isPrivate,
          },
          {
            headers: {
              Authorization: "Bearer " + (await getToken("accessToken")),
            },
          }
        );
        toast.show({
          placement: "bottom right",
          render: ({ id }) => {
            return (
              <Toast nativeID={id} variant="solid" action="success">
                <ToastTitle>Edited successfully</ToastTitle>
              </Toast>
            );
          },
        });
      } catch (err) {
        console.log(err);
        if (err.status === 403) {
          const { refreshTokenValid } = await refreshAccessToken();
          if (!refreshTokenValid) {
            closeOverlays();
            router.push("/auth/splash-screen");
          }
        }
      }
      await getAppUser();
    }
  }

  async function onSubmit(): Promise<void> {
    const location = await Location.getCurrentPositionAsync({});
    try {
      await axios.post(
        `${ApiUrl}/api/posts/upload`,
        {
          content,
          mediaUrl,
          latitude: location.coords.latitude,
          longitude: location.coords.longitude,
        },
        {
          headers: {
            Authorization: "Bearer " + (await getToken("accessToken")),
          },
        }
      );
      toast.show({
        placement: "bottom right",
        render: ({ id }) => {
          return (
            <Toast nativeID={id} variant="solid" action="success">
              <ToastTitle>Post uploaded successfully!</ToastTitle>
            </Toast>
          );
        },
      });
      setMediaUrl("");
      setContent("");
      getPosts();
      setShowAddPostDrawer(false);
    } catch (err) {
      console.log(err);
      if (err.status === 403) {
        const { refreshTokenValid } = await refreshAccessToken();
        if (!refreshTokenValid) {
          closeOverlays();
          router.push("/auth/splash-screen");
        }
      }
    }
  }

  return (
    <>
      <MapUI
        markers={
          !posts
            ? null
            : groupSimilarPosts(
                posts.map((post) => ({
                  postId: post.postId,
                  latitude: post.latitude,
                  longitude: post.longitude,
                  content: post.content,
                  userId: post.userId,
                  mediaUrl: post.mediaUrl,
                  createdAt: new Date(post.createdAt),
                })),
                0.5
              )
        }
        router={router}
        fetchPosts={getPosts}
      />
      <Fab
        className="m-5 bg-mainColor-0"
        style={{
          top: insets.top,
          left: insets.left,
        }}
        size="lg"
        placement="top left"
        isHovered={false}
        isDisabled={false}
        isPressed={false}
        onPress={() => {
          setShowAddPostDrawer(true);
        }}
      >
        <FabIcon as={Plus} size="xl" className="text-typography-100" />
        <FabLabel className="text-typography-100">Add Post</FabLabel>
      </Fab>
      <Fab
        className="m-5 w-[50px] h-[50px] bg-mainColor-0"
        style={{
          top: insets.top,
          right: insets.right,
        }}
        size="lg"
        placement="top right"
        isHovered={false}
        isDisabled={false}
        isPressed={false}
        onPress={() => {
          setShowProfileDrawer(true);
        }}
      >
        <Avatar size="md" className="p-2 bg-mainColor-0">
          <AvatarImage
            source={
              !appUser
                ? require("@/assets/images/user.png")
                : !appUser.profilePictureUrl
                  ? require("@/assets/images/user.png")
                  : {
                      uri: appUser.profilePictureUrl,
                    }
            }
          />
        </Avatar>
      </Fab>
      <Fab
        className="m-3 mx-10 absolute items-center justify-between gap-5 bg-transparent"
        placement="bottom center"
        style={{
          bottom: insets.bottom,
          left: insets.left,
          right: insets.right,
        }}
      >
        <Pressable
          className="rounded-full p-3 bg-mainColor-0"
          onPress={() => {
            const now = new Date();
            const currentDateString = !date ? now : date;
            const newDate = new Date(currentDateString);
            newDate.setDate(newDate.getDate() - 1);
            let yearStr = String(newDate.getFullYear());
            let monthStr = String(newDate.getMonth() + 1);
            monthStr = monthStr.length === 1 ? `0${monthStr}` : monthStr;
            let dateStr = String(newDate.getDate());
            dateStr = dateStr.length === 1 ? `0${dateStr}` : dateStr;
            setDate(`${yearStr}-${monthStr}-${dateStr}`);
          }}
        >
          <Icon as={ArrowLeft} className="text-typography-100" />
        </Pressable>
        <Pressable
          className="rounded-full bg-mainColor-0 px-6 py-3"
          onPress={() => {
            setDate("");
          }}
        >
          <Text className="text-typography-100 text-lg">
            {!date ? "Recent 7 days" : date}
          </Text>
        </Pressable>
        <Pressable
          className="rounded-full p-3 bg-mainColor-0"
          onPress={() => {
            const now = new Date();
            const currentDateString = !date ? now : date;
            const newDate = new Date(currentDateString);
            newDate.setDate(newDate.getDate() + 1);
            let yearStr = String(newDate.getFullYear());
            let monthStr = String(newDate.getMonth() + 1);
            monthStr = monthStr.length === 1 ? `0${monthStr}` : monthStr;
            let dateStr = String(newDate.getDate());
            dateStr = dateStr.length === 1 ? `0${dateStr}` : dateStr;
            setDate(`${yearStr}-${monthStr}-${dateStr}`);
          }}
        >
          <Icon as={ArrowRight} className="text-typography-100" />
        </Pressable>
      </Fab>
      <Drawer
        isOpen={showAddPostDrawer}
        onClose={() => {
          setShowAddPostDrawer(false);
        }}
        size="full"
        anchor="bottom"
      >
        <DrawerBackdrop />
        <DrawerContent
          style={{
            height: Dimensions.get("window").height - insets.top,
            padding: insets.bottom,
            borderTopLeftRadius: 25,
            borderTopRightRadius: 25,
            paddingBottom: insets.bottom + 50,
          }}
        >
          <DrawerHeader>
            <Heading size="3xl">Add Post</Heading>
          </DrawerHeader>
          <DrawerBody>
            <ScrollView className="h-full">
              <FormControl>
                <Pressable onPress={pickImage} className="w-full p-4">
                  <Center className="w-full aspect-square">
                    <Center
                      className={
                        !mediaUrl
                          ? "w-[110px] h-[110px] p-3 border-background-400 border-2 rounded-xl"
                          : "w-full aspect-square"
                      }
                    >
                      <Image
                        source={
                          !mediaUrl
                            ? require("@/assets/images/plus.png")
                            : {
                                uri: mediaUrl,
                              }
                        }
                        alt="Image"
                        className={
                          !mediaUrl
                            ? "w-[60px] h-[60px]"
                            : "w-full aspect-square"
                        }
                      />
                    </Center>
                  </Center>
                </Pressable>
              </FormControl>
              <FormControl>
                <Textarea className="border-0">
                  <TextareaInput
                    placeholder="Explain media..."
                    onChangeText={setContent}
                  />
                </Textarea>
              </FormControl>
            </ScrollView>
          </DrawerBody>
          <DrawerFooter>
            <HStack className="flex-1 justify-between">
              <Button
                onPress={() => {
                  setShowAddPostDrawer(false);
                }}
                className="w-1/3"
                action="secondary"
                variant="outline"
              >
                <ButtonText>Close</ButtonText>
              </Button>
              <Button className="w-1/2" action="primary" onPress={onSubmit}>
                <ButtonText>Upload</ButtonText>
                <ButtonIcon as={Upload} />
              </Button>
            </HStack>
          </DrawerFooter>
        </DrawerContent>
      </Drawer>
      <Drawer
        isOpen={showProfileDrawer}
        onClose={() => {
          setShowAddPostDrawer(false);
        }}
        size="lg"
        anchor="bottom"
      >
        <DrawerBackdrop />
        <DrawerContent
          style={{
            padding: insets.bottom,
            borderTopLeftRadius: 25,
            borderTopRightRadius: 25,
            paddingBottom: insets.bottom + 50,
          }}
        >
          <DrawerHeader>
            <Heading size="2xl">@{!appUser ? "" : appUser.username}</Heading>
          </DrawerHeader>
          <DrawerBody>
            <Center>
              <VStack space="xl" className="justify-center items-center">
                <VStack space="lg">
                  <Pressable onPress={pickProfileImage}>
                    <Center>
                      <Avatar size="2xl">
                        {!appUser ? undefined : !appUser.profilePictureUrl ? (
                          <Icon
                            as={UserIcon}
                            className="w-[50px] h-[50px] text-typography-600"
                          />
                        ) : (
                          <AvatarImage
                            source={{ uri: appUser.profilePictureUrl }}
                          />
                        )}
                      </Avatar>
                      <Text size="sm" className="mt-1">
                        Press to change
                      </Text>
                    </Center>
                  </Pressable>
                  <Center>
                    <Heading size="xl" className="gap-2">
                      {!appUser ? "" : appUser.fullName}
                    </Heading>
                  </Center>
                </VStack>
                <HStack space="lg">
                  <Pressable
                    onPress={() => {
                      setShowFollowersModal(true);
                    }}
                  >
                    <Center>
                      <Text className="text-typography-800" size="md">
                        {appUserFollowers.length}
                      </Text>
                      <Text className="text-typography-800" size="sm">
                        Followers
                      </Text>
                    </Center>
                  </Pressable>
                  <Box className="bg-typography-800 w-[1px] h-full"></Box>
                  <Pressable
                    onPress={() => {
                      setShowFollowingsModal(true);
                    }}
                  >
                    <Center>
                      <Text className="text-typography-800" size="md">
                        {appUserFollowings.length}
                      </Text>
                      <Text className="text-typography-800" size="sm">
                        Followings
                      </Text>
                    </Center>
                  </Pressable>
                  <Box className="bg-typography-800 w-[1px] h-full"></Box>
                  <Center>
                    <Text className="text-typography-800" size="md">
                      {!appUser ? "" : appUser.createdAt.toLocaleDateString()}
                    </Text>
                    <Text className="text-typography-800" size="sm">
                      Created At
                    </Text>
                  </Center>
                </HStack>
                <VStack className="mt-6 border-background-700 border-[0px] rounded-md p-2 w-[250px] h-[100px]">
                  <ScrollView>
                    {!appUser ? (
                      ""
                    ) : !appUser.bio ? (
                      <Text className="text-typography-400">
                        Edit profile to write on bio...
                      </Text>
                    ) : (
                      <Text className="text-typography-800">{appUser.bio}</Text>
                    )}
                  </ScrollView>
                </VStack>
              </VStack>
            </Center>
          </DrawerBody>
          <DrawerFooter>
            <VStack space="md" className="flex-1">
              <Button
                action="primary"
                onPress={() => {
                  setShowEditProfileModal(true);
                  setEditedBio(appUser.bio);
                  setEditedProfileMediaUrl(appUser.profilePictureUrl);
                  setEditedFullName(appUser.fullName);
                  setEditedIsPrivate(appUser.isPrivate);
                  setEditedPassword("");
                }}
              >
                <ButtonText>Edit Profile</ButtonText>
                <ButtonIcon as={Edit} />
              </Button>
              <HStack className="justify-between">
                <Button
                  onPress={() => {
                    setShowProfileDrawer(false);
                  }}
                  variant="outline"
                  className="w-1/3"
                >
                  <ButtonText>Close</ButtonText>
                </Button>
                <Button
                  action="negative"
                  className="w-1/2"
                  onPress={() => {
                    saveToken("refreshToken", "");
                    saveToken("accessToken", "");
                    closeOverlays();
                    router.push("/auth/splash-screen");
                  }}
                >
                  <ButtonText>Logout</ButtonText>
                  <ButtonIcon as={LogOut} />
                </Button>
              </HStack>
            </VStack>
          </DrawerFooter>
        </DrawerContent>
      </Drawer>
      <Modal
        isOpen={showEditProfileModal}
        onClose={() => {
          setShowEditProfileModal(false);
        }}
        size="md"
        avoidKeyboard={true}
        closeOnOverlayClick={false}
      >
        <ModalBackdrop />
        <ModalContent>
          <ModalHeader>
            <ModalCloseButton />
          </ModalHeader>
          <ModalBody>
            <VStack>
              <Heading>Edit Profile</Heading>
              <VStack className="gap-5 w-full">
                <VStack className="gap-1">
                  <VStack className="rounded-md">
                    <Text size="sm" className="mb-1">
                      Bio
                    </Text>
                    <Textarea>
                      <TextareaInput
                        defaultValue={!appUser ? "" : appUser.bio}
                        placeholder="Your bio..."
                        onChangeText={setEditedBio}
                      />
                    </Textarea>
                  </VStack>
                </VStack>
                <VStack className="gap-1">
                  <Text size="sm" className="mb-1">
                    Full Name
                  </Text>
                  <Input variant="outline" size="md">
                    <InputField
                      defaultValue={!appUser ? "" : appUser.fullName}
                      placeholder="Full Name..."
                      onChangeText={setEditedFullName}
                    />
                  </Input>
                </VStack>
                {/* <VStack className="gap-1">
                  <Text size="sm">New Password</Text>
                  <Input variant="outline" size="md">
                    <InputField
                      type="password"
                      placeholder="Leave empty if you don't want to change"
                      onChangeText={setEditedFullName}
                    />
                  </Input>
                </VStack> */}
                <VStack className="gap-1">
                  <HStack className="items-center">
                    <Switch
                      size="sm"
                      defaultValue={!appUser ? false : appUser.isPrivate}
                      onValueChange={setEditedIsPrivate}
                    />
                    <Text size="sm" className="mr-1">
                      Private
                    </Text>
                  </HStack>
                </VStack>
              </VStack>
            </VStack>
          </ModalBody>
          <ModalFooter>
            <Button
              variant="outline"
              action="secondary"
              onPress={() => {
                setShowEditProfileModal(false);
              }}
            >
              <ButtonText>Cancel</ButtonText>
            </Button>
            <Button
              onPress={() => {
                (async () => {
                  console.log({
                    username: appUser.username,
                    email: appUser.email,
                    password: editedPassword,
                    fullName: editedFullName,
                    bio: editedBio,
                    profilePictureUrl: editedProfileMediaUrl,
                    isPrivate: editedIsPrivate,
                  });
                  try {
                    await axios.put(
                      `${ApiUrl}/api/users/edit`,
                      {
                        username: appUser.username,
                        email: appUser.email,
                        password: editedPassword,
                        fullName: editedFullName,
                        bio: editedBio,
                        profilePictureUrl: editedProfileMediaUrl,
                        isPrivate: editedIsPrivate,
                      },
                      {
                        headers: {
                          Authorization:
                            "Bearer " + (await getToken("accessToken")),
                        },
                      }
                    );
                    toast.show({
                      placement: "bottom right",
                      render: ({ id }) => {
                        return (
                          <Toast nativeID={id} variant="solid" action="success">
                            <ToastTitle>Edited successfully</ToastTitle>
                          </Toast>
                        );
                      },
                    });
                  } catch (err) {
                    console.log(err);
                    if (err.status === 403) {
                      const { refreshTokenValid } = await refreshAccessToken();
                      if (!refreshTokenValid) {
                        closeOverlays();
                        router.push("/auth/splash-screen");
                      }
                    }
                  }
                  getAppUser();
                })();
                setShowProfileDrawer(false);
                setShowEditProfileModal(false);
              }}
            >
              <ButtonText>Edit</ButtonText>
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
      <Modal
        isOpen={showFollowersModal}
        onClose={() => {
          setShowFollowersModal(false);
        }}
        size="md"
        avoidKeyboard={true}
        closeOnOverlayClick={false}
      >
        <ModalBackdrop />
        <ModalContent>
          <ModalHeader>
            <ModalCloseButton />
          </ModalHeader>
          <ModalBody>
            <ScrollView>
              <VStack space="md">
                {appUserFollowers.map((follower) => (
                  <HStack className="justify-between">
                    {follower.username}
                  </HStack>
                ))}
              </VStack>
            </ScrollView>
          </ModalBody>
          <ModalFooter>
            <VStack space="md" className="flex-1">
              <Button
                onPress={() => {
                  setShowFollowersModal(false);
                }}
                variant="outline"
                className="w-1/3"
              >
                <ButtonText>Close</ButtonText>
              </Button>
            </VStack>
          </ModalFooter>
        </ModalContent>
      </Modal>
      <Modal
        isOpen={showFollowingsModal}
        onClose={() => {
          setShowFollowingsModal(false);
        }}
        size="md"
        avoidKeyboard={true}
        closeOnOverlayClick={false}
      >
        <ModalBackdrop />
        <ModalContent>
          <ModalHeader>
            <ModalCloseButton />
          </ModalHeader>
          <ModalBody></ModalBody>
          <ModalFooter>
            <VStack space="md" className="flex-1">
              <Button
                onPress={() => {
                  setShowFollowingsModal(false);
                }}
                variant="outline"
                className="w-1/3"
              >
                <ButtonText>Close</ButtonText>
              </Button>
            </VStack>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </>
  );
}
