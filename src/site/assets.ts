export const siteAssets = {
  wordmarkBlack: require('../../assets/site/brand/asu-wordmark-black.png'),
  wordmarkWhite: require('../../assets/site/brand/asu-wordmark-white.png'),
  introPoster: require('../../assets/site/intro-poster.jpg'),
  introVideo: require('../../assets/site/intro.mp4'),
  worldMap: require('../../assets/site/homepage/world-map.webp'),
  showroom: [
    require('../../assets/site/showroom/showroom-01.webp'),
    require('../../assets/site/showroom/showroom-02.webp'),
    require('../../assets/site/showroom/showroom-03.webp'),
    require('../../assets/site/showroom/showroom-04.webp'),
    require('../../assets/site/showroom/showroom-05.webp'),
    require('../../assets/site/showroom/showroom-06.webp'),
  ],
  brands: {
    'Mercedes-Benz': require('../../assets/site/brands/mercedes-benz.jpg'),
    'Range Rover': require('../../assets/site/brands/range-rover.png'),
    'Rolls-Royce': require('../../assets/site/brands/rolls-royce.png'),
    Cadillac: require('../../assets/site/brands/cadillac.png'),
    Lexus: require('../../assets/site/brands/lexus.png'),
    Toyota: require('../../assets/site/brands/toyota.png'),
    Genesis: require('../../assets/site/brands/genesis.png'),
    BMW: require('../../assets/site/brands/bmw.png'),
    Lamborghini: require('../../assets/site/brands/lamborghini.png'),
    Porsche: require('../../assets/site/brands/porsche.png'),
  } as Record<string, number>,
};

export const brandNames = Object.keys(siteAssets.brands);
