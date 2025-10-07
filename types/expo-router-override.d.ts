// Wide, safe typings to run without expo-router typegen
declare module "expo-router" {
  export const Link: any;
  export const Stack: any;
  export const Tabs: any;
  export const Slot: any;
  export const useRouter: any;
  export const router: any;
  export const Redirect: any;

  export type Href = string;
  export type RelativePathString = string;
  export type ExternalPathString = string;
}
