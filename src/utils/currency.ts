export function fmt(amount:number, currency?:string){
  const cur=currency||process.env.EXPO_PUBLIC_DEFAULT_CURRENCY||"PLN";
  return new Intl.NumberFormat(undefined,{style:"currency",currency:cur}).format(amount);
}