export type Lang = 'pl' | 'en';
export const t = (lang: Lang, key: string) => {
  const dict: Record<string, Record<string,string>> = {
    pl: { calendar:'Kalendarz',language:'Język',polish:'Polski',english:'Angielski',date:'Data',time:'Czas',year:'Rok',month:'Miesiąc',day:'Dzień',hour:'Godzina',minute:'Minuta',reset:'Reset',confirm:'Zatwierdź',openNativeDate:'Wybierz datę',openNativeTime:'Wybierz czas',selected:'Wybrano'},
    en: { calendar:'Calendar',language:'Language',polish:'Polish',english:'English',date:'Date',time:'Time',year:'Year',month:'Month',day:'Day',hour:'Hour',minute:'Minute',reset:'Reset',confirm:'Confirm',openNativeDate:'Pick date',openNativeTime:'Pick time',selected:'Selected'}
  };
  const l = dict[lang] ?? dict['pl'];
  return l[key] ?? key;
};
