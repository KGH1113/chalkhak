import { useState, useEffect } from "react";

import {
  StyleSheet,
  View,
  Platform,
  Dimensions,
  TextInput,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import MapView, {
  PROVIDER_GOOGLE,
  PROVIDER_DEFAULT,
  Marker,
} from "react-native-maps";
import * as Location from "expo-location";

import { Spinner } from "@/components/ui/spinner";
import {
  Drawer,
  DrawerBackdrop,
  DrawerBody,
  DrawerContent,
  DrawerHeader,
  DrawerFooter,
} from "@/components/ui/drawer";
import { Button, ButtonIcon, ButtonText } from "@/components/ui/button";
import { Heading } from "@/components/ui/heading";
import { Text } from "@/components/ui/text";
import { Image } from "react-native";
import { Center } from "@/components/ui/center";
import { VStack } from "@/components/ui/vstack";
import { HStack } from "@/components/ui/hstack";
import {
  Avatar,
  AvatarBadge,
  AvatarFallbackText,
  AvatarImage,
  AvatarGroup,
} from "@/components/ui/avatar";
import { Box } from "./ui/box";
import { CloseIcon, Icon } from "./ui/icon";
import { Pressable } from "./ui/pressable";
import { Menu, MenuItem, MenuItemLabel } from "./ui/menu";
import { Toast, ToastTitle, useToast } from "@/components/ui/toast";
import { Portal } from "./ui/portal";

import { Edit, EllipsisVertical, EyeOff, User } from "lucide-react-native";

import axios from "axios";
import { ApiUrl } from "@/auth/ApiUrl";
import { getToken } from "@/auth/SecureStore";
import { Router } from "expo-router";
import { refreshAccessToken } from "@/auth/RefreshToken";
import * as ImagePicker from "expo-image-picker";
import Mime from "mime";
import {
  Modal,
  ModalBackdrop,
  ModalBody,
  ModalCloseButton,
  ModalContent,
  ModalFooter,
  ModalHeader,
} from "./ui/modal";
import { Textarea, TextareaInput } from "./ui/textarea";
import { ScrollView } from "react-native-reanimated/lib/typescript/Animated";
import { clearData, getData, storeData } from "@/utils/AsyncStorage";

interface MarkerType {
  postId: string;
  latitude: number;
  longitude: number;
  content: string;
  userId: string;
  mediaUrl: string;
  createdAt: Date;
}

interface GroupedPost {
  latitude: number;
  longitude: number;
  groupedPosts: MarkerType[];
}

interface MapUiProps {
  markers?: GroupedPost[];
  router: Router;
  fetchPosts: () => Promise<void>;
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

export default function MapUI({ markers, router, fetchPosts }: MapUiProps) {
  const [region, setRegion] = useState<{
    latitude: number;
    longitude: number;
    latitudeDelta: number;
    longitudeDelta: number;
  }>();
  const [errorMsg, setErrorMsg] = useState<string>("");
  const [showDrawer, setShowDrawer] = useState<boolean>(false);
  const [showEditPostModal, setShowEditPostModal] = useState<boolean>(false);
  const [drawerPostData, setDrawerPostData] = useState<MarkerType[]>([]);
  const [drawerPostUploaders, setDrawerPostUploaders] = useState<
    {
      userId: string;
      username: string;
      email: string;
      createdAt: Date;
      fullName?: string;
      bio?: string;
      profilePictureUrl?: string;
      isPrivate: boolean;
    }[]
  >([]);
  const [appUserId, setAppUserId] = useState<string>("");
  const [editedContent, setEditedContent] = useState<string>("");
  const [editedImageUri, setEditedImageUri] = useState<string>("");
  const [editedMediaUrl, setEditedMediaUrl] = useState<string>("");
  const [viewedPosts, setViewedPosts] = useState<string[]>([]);

  const insets = useSafeAreaInsets();

  const toast = useToast();

  useEffect(() => {
    (async () => {
      setAppUserId(await getToken("userId"));

      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== "granted") {
        setErrorMsg("Permission to access location was denied");
        return;
      }

      const location = await Location.getCurrentPositionAsync({});
      const { latitude, longitude } = location.coords;
      setRegion({
        latitude,
        longitude,
        latitudeDelta: 1,
        longitudeDelta: 1,
      });
      console.log({ latitude, longitude });

      const viewedPostsData: string[] = await getData("viewedPosts");
      if (!viewedPostsData) {
        setViewedPosts([]);
        await storeData("viewedPosts", "[]");
      } else {
        setViewedPosts(viewedPostsData);
      }
    })();
  }, []);

  useEffect(() => {
    if (drawerPostData.length === 0) {
      return;
    }
    drawerPostData.forEach(async (post) => {
      try {
        const res = await axios.post(
          `${ApiUrl}/api/users/get`,
          { userId: post.userId },
          {
            headers: {
              Authorization: "Bearer " + (await getToken("accessToken")),
            },
          }
        );
        const newDrawerPostUploaders = [...drawerPostUploaders];
        newDrawerPostUploaders.push(res.data);
        setDrawerPostUploaders(newDrawerPostUploaders);
      } catch (err) {
        console.log(err);
        if (err.status === 403) {
          const { refreshTokenValid } = await refreshAccessToken();
          if (!refreshTokenValid) {
            setShowDrawer(false);
            setShowEditPostModal(false);
            router.push("/auth/splash-screen");
          }
        }
      }
    });
  }, [drawerPostData]);

  const UserProfileIcon = ({
    userId,
    showBadge,
  }: {
    userId: string;
    showBadge: boolean;
  }) => {
    const [user, setUser] = useState<User>();

    useEffect(() => {
      (async () => {
        try {
          const res = await axios.post(
            `${ApiUrl}/api/users/get`,
            { userId },
            {
              headers: {
                Authorization: "Bearer " + (await getToken("accessToken")),
              },
            }
          );
          setUser(res.data);
        } catch (err) {
          console.log(err);
          if (err.status === 403) {
            const { refreshTokenValid } = await refreshAccessToken();
            if (!refreshTokenValid) {
              setShowDrawer(false);
              setShowEditPostModal(false);
              router.push("/auth/splash-screen");
            }
          }
        }
      })();
    }, []);

    return (
      <>
        {user && (
          <Avatar
            size="md"
            className={`bg-indigo-300 border-2 border-indigo-600`}
          >
            {!user ? undefined : !user.profilePictureUrl ? (
              <Icon as={User} size="xl" className={`text-indigo-600`} />
            ) : (
              <AvatarImage
                source={{
                  uri: user.profilePictureUrl,
                }}
              />
            )}
            {showBadge ? <AvatarBadge /> : <></>}
          </Avatar>
        )}
      </>
    );
  };

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
      setEditedImageUri(selectedImageUri);

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
        setEditedMediaUrl(res.data.fileUrl);
      } catch (err) {
        console.log(err);
        if (err.status === 403) {
          const { refreshTokenValid } = await refreshAccessToken();
          if (!refreshTokenValid) {
            setShowDrawer(false);
            setShowEditPostModal(false);
            router.push("/auth/splash-screen");
          }
        }
      }
    }
  }

  return (
    <>
      {region ? (
        <MapView
          style={styles.map}
          initialRegion={region}
          provider={PROVIDER_DEFAULT}
          customMapStyle={generatedMapStyle}
          showsUserLocation={true}
        >
          {markers?.map((marker, i) => (
            <Marker
              key={i}
              coordinate={{
                latitude: marker.latitude,
                longitude: marker.longitude,
              }}
              onPress={() => {
                setShowDrawer(true);
                setDrawerPostData(marker.groupedPosts);
                const newViewedPosts = marker.groupedPosts
                  .filter((post) => !viewedPosts.includes(post.postId))
                  .map((post) => post.postId)
                  .concat([...viewedPosts]);
                setViewedPosts(newViewedPosts);
                (async () => {
                  await storeData(
                    "viewedPosts",
                    JSON.stringify(newViewedPosts)
                  );
                })();
              }}
            >
              <VStack>
                <AvatarGroup>
                  <>
                    {marker.groupedPosts.slice(0, 3).map((post, j) => (
                      <UserProfileIcon
                        key={j}
                        userId={post.userId}
                        showBadge={!viewedPosts.includes(post.postId)}
                      />
                    ))}
                  </>
                  {marker.groupedPosts.slice(3).length === 0 ? (
                    <></>
                  ) : (
                    <Avatar>
                      <AvatarFallbackText>
                        {"+ " + marker.groupedPosts.slice(3).length + ""}
                      </AvatarFallbackText>
                    </Avatar>
                  )}
                </AvatarGroup>
              </VStack>
            </Marker>
          ))}
        </MapView>
      ) : (
        <VStack className="h-full w-full items-center justify-center">
          <Spinner />
        </VStack>
      )}
      <Drawer
        isOpen={showDrawer}
        onClose={() => {
          setShowDrawer(false);
          setShowEditPostModal(false);
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
          }}
        >
          <DrawerBody>
            <VStack space="lg">
              {drawerPostUploaders.length === 0 || !drawerPostData ? (
                <></>
              ) : (
                drawerPostData.map((drawerPost, index) => {
                  let drawerPostUploader: {
                    userId: string;
                    username: string;
                    email: string;
                    createdAt: Date;
                    fullName?: string;
                    bio?: string;
                    profilePictureUrl?: string;
                    isPrivate: boolean;
                  } = {
                    userId: "",
                    username: "",
                    email: "",
                    createdAt: new Date(),
                    fullName: "",
                    bio: "",
                    profilePictureUrl: "",
                    isPrivate: false,
                  };
                  drawerPostUploaders.forEach((d) => {
                    if (d.userId === drawerPost.userId) {
                      drawerPostUploader = { ...d };
                    }
                  });
                  return (
                    <VStack key={index}>
                      <VStack space="sm">
                        <HStack className="justify-between items-center">
                          <HStack space="md">
                            <Avatar>
                              <AvatarFallbackText>
                                {!drawerPostUploader
                                  ? ""
                                  : drawerPostUploader.username}
                              </AvatarFallbackText>
                              <AvatarImage
                                source={
                                  !drawerPostUploader.profilePictureUrl
                                    ? undefined
                                    : {
                                        uri: drawerPostUploader.profilePictureUrl,
                                      }
                                }
                              />
                            </Avatar>
                            <VStack>
                              <Heading size="sm">
                                @{drawerPostUploader.username}
                              </Heading>
                              <Text size="sm">
                                Uploaded at{" "}
                                {drawerPost.createdAt.toLocaleDateString()}
                              </Text>
                            </VStack>
                          </HStack>
                          {drawerPostUploader.userId === appUserId ? (
                            <Menu
                              placement="left"
                              offset={5}
                              selectionMode="single"
                              onSelectionChange={(keys: Set<string>) => {
                                const selected = Array.from(keys)[0];
                                switch (selected) {
                                  case "edit":
                                    setEditedContent(drawerPost.content);
                                    setEditedMediaUrl(drawerPost.mediaUrl);
                                    setShowEditPostModal(true);
                                    break;
                                  case "hide":
                                    (async () => {
                                      try {
                                        await axios.put(
                                          `${ApiUrl}/api/posts/edit`,
                                          {
                                            postId: drawerPost.postId,
                                            content: drawerPost.content,
                                            mediaUrl: drawerPost.mediaUrl,
                                            latitude: drawerPost.latitude,
                                            longitude: drawerPost.longitude,
                                            hidden: true,
                                          },
                                          {
                                            headers: {
                                              Authorization:
                                                "Bearer " +
                                                (await getToken("accessToken")),
                                            },
                                          }
                                        );
                                        toast.show({
                                          placement: "bottom right",
                                          render: ({ id }) => {
                                            return (
                                              <Toast
                                                nativeID={id}
                                                variant="solid"
                                                action="success"
                                              >
                                                <ToastTitle>
                                                  Hid successfully
                                                </ToastTitle>
                                              </Toast>
                                            );
                                          },
                                        });
                                      } catch (err) {
                                        console.log(err);
                                        if (err.status === 403) {
                                          const { refreshTokenValid } =
                                            await refreshAccessToken();
                                          if (!refreshTokenValid) {
                                            setShowDrawer(false);
                                            setShowEditPostModal(false);
                                            router.push("/auth/splash-screen");
                                          }
                                        }
                                      }
                                    })();
                                    break;
                                }
                              }}
                              trigger={({ ...trigerProps }) => (
                                <Pressable {...trigerProps}>
                                  <Icon as={EllipsisVertical} />
                                </Pressable>
                              )}
                            >
                              <MenuItem key="edit" textValue="Edit">
                                <Icon as={Edit} className="mr-2" />
                                <MenuItemLabel size="sm">Edit</MenuItemLabel>
                              </MenuItem>
                              <MenuItem key="hide" textValue="Hide">
                                <Icon
                                  as={EyeOff}
                                  className="mr-2 text-red-500"
                                />
                                <MenuItemLabel
                                  size="sm"
                                  className="text-red-500"
                                >
                                  Hide
                                </MenuItemLabel>
                              </MenuItem>
                            </Menu>
                          ) : (
                            <></>
                          )}
                        </HStack>
                        <VStack className="w-full p-4">
                          <Center className="w-full aspect-square">
                            <Image
                              source={
                                !drawerPost.mediaUrl
                                  ? require("@/assets/images/plus.png")
                                  : {
                                      uri: drawerPost.mediaUrl,
                                    }
                              }
                              alt="Image"
                              className="w-full aspect-square"
                            />
                          </Center>
                        </VStack>
                        <Box className="w-full h-[1px] bg-background-500"></Box>
                        <VStack className="gap-1">
                          <VStack className="rounded-md px-3">
                            <Text className="w-full p-2 web:outline-0 web:outline-none flex-1 color-typography-900 align-text-top placeholder:text-typography-500 web:cursor-text web:data-[disabled=true]:cursor-not-allowed">
                              <Text className="text-primary-400 font-bold">
                                @{drawerPostUploader.username}
                                {"  "}
                              </Text>
                              <Text>{drawerPost.content}</Text>
                            </Text>
                          </VStack>
                        </VStack>
                        <Box className="w-full h-[1px] bg-background-500"></Box>
                      </VStack>

                      <Modal
                        isOpen={showEditPostModal}
                        onClose={() => {
                          setShowEditPostModal(false);
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
                              <Heading>Edit Post</Heading>
                              <VStack className="gap-5 w-full">
                                <Pressable
                                  onPress={pickImage}
                                  className="w-full p-4"
                                >
                                  <Center className="w-full aspect-square">
                                    <Center className={"w-full aspect-square"}>
                                      <Image
                                        source={{
                                          uri: !editedImageUri
                                            ? editedMediaUrl
                                            : editedImageUri,
                                        }}
                                        alt="Image"
                                        className={"w-full aspect-square"}
                                      />
                                    </Center>
                                  </Center>
                                  <Text size="sm" className="mt-1">
                                    Press media to change
                                  </Text>
                                </Pressable>
                                <VStack className="gap-1">
                                  <VStack className="rounded-md">
                                    <Textarea className="border-0">
                                      <TextareaInput
                                        defaultValue={drawerPost.content}
                                        placeholder="Explain media..."
                                        onChangeText={setEditedContent}
                                      />
                                    </Textarea>
                                    <Text size="sm" className="mt-1">
                                      Press to edit
                                    </Text>
                                  </VStack>
                                </VStack>
                              </VStack>
                            </VStack>
                          </ModalBody>
                          <ModalFooter>
                            <Button
                              variant="outline"
                              action="secondary"
                              onPress={() => {
                                setShowEditPostModal(false);
                              }}
                            >
                              <ButtonText>Cancel</ButtonText>
                            </Button>
                            <Button
                              onPress={() => {
                                (async () => {
                                  try {
                                    await axios.put(
                                      `${ApiUrl}/api/posts/edit`,
                                      {
                                        postId: drawerPost.postId,
                                        content: editedContent,
                                        mediaUrl: editedMediaUrl,
                                        latitude: drawerPost.latitude,
                                        longitude: drawerPost.longitude,
                                        hidden: false,
                                      },
                                      {
                                        headers: {
                                          Authorization:
                                            "Bearer " +
                                            (await getToken("accessToken")),
                                        },
                                      }
                                    );
                                    toast.show({
                                      placement: "bottom right",
                                      render: ({ id }) => {
                                        return (
                                          <Toast
                                            nativeID={id}
                                            variant="solid"
                                            action="success"
                                          >
                                            <ToastTitle>
                                              Edited successfully
                                            </ToastTitle>
                                          </Toast>
                                        );
                                      },
                                    });
                                  } catch (err) {
                                    console.log(err);
                                    if (err.status === 403) {
                                      const { refreshTokenValid } =
                                        await refreshAccessToken();
                                      if (!refreshTokenValid) {
                                        setShowDrawer(false);
                                        setShowEditPostModal(false);
                                        router.push("/auth/splash-screen");
                                      }
                                    }
                                  }
                                  await fetchPosts();
                                })();
                                setShowEditPostModal(false);
                                setShowDrawer(false);
                              }}
                            >
                              <ButtonText>Edit</ButtonText>
                            </Button>
                          </ModalFooter>
                        </ModalContent>
                      </Modal>
                    </VStack>
                  );
                })
              )}
            </VStack>
          </DrawerBody>
          <DrawerFooter className="h-[500px]">
            <HStack className="flex-1 justify-between">
              <Button
                onPress={() => {
                  setShowDrawer(false);
                }}
                className="w-1/3"
                action="secondary"
                variant="outline"
              >
                <ButtonText>Close</ButtonText>
              </Button>
            </HStack>
          </DrawerFooter>
        </DrawerContent>
      </Drawer>
    </>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
  },
  map: {
    width: "100%",
    height: "100%",
  },
});

const generatedMapStyle = [
  {
    featureType: "administrative.land_parcel",
    stylers: [
      {
        visibility: "off",
      },
    ],
  },
  {
    featureType: "administrative.neighborhood",
    stylers: [
      {
        visibility: "off",
      },
    ],
  },
  {
    featureType: "poi",
    elementType: "labels.text",
    stylers: [
      {
        visibility: "off",
      },
    ],
  },
  {
    featureType: "poi.business",
    stylers: [
      {
        visibility: "off",
      },
    ],
  },
  {
    featureType: "road",
    stylers: [
      {
        visibility: "off",
      },
    ],
  },
  {
    featureType: "road",
    elementType: "labels",
    stylers: [
      {
        visibility: "off",
      },
    ],
  },
  {
    featureType: "road",
    elementType: "labels.icon",
    stylers: [
      {
        visibility: "off",
      },
    ],
  },
  {
    featureType: "transit",
    stylers: [
      {
        visibility: "off",
      },
    ],
  },
  {
    featureType: "water",
    elementType: "labels.text",
    stylers: [
      {
        visibility: "off",
      },
    ],
  },
];
