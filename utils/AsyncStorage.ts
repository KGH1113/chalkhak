import AsyncStorage from "@react-native-async-storage/async-storage";

export async function storeData(key: string, value: string) {
  try {
    await AsyncStorage.setItem(key, value);
  } catch (e) {
    console.log(e);
  }
}

export async function getData(key: string): Promise<any> {
  try {
    const loadedData = await AsyncStorage.getItem(key);
    if (!loadedData) {
      await AsyncStorage.setItem(key, "");
    }
    return JSON.parse(loadedData);
  } catch (e) {
    console.log(e);
    return null;
  }
}

export async function clearData() {
  await AsyncStorage.clear();
  console.log("Asyncstorage data cleared");
}
