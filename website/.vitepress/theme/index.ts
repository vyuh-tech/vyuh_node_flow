import DefaultTheme from 'vitepress/theme';
import type { Theme } from 'vitepress';
import HomePage from './HomePage.vue';
import ProPage from './ProPage.vue';
import NavProBadge from './components/NavProBadge.vue';
import PackageShields from './components/PackageShields.vue';
import PubVersion from './components/PubVersion.vue';
import './style.css';

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component('HomePage', HomePage);
    app.component('ProPage', ProPage);
    app.component('NavProBadge', NavProBadge);
    app.component('PackageShields', PackageShields);
    app.component('PubVersion', PubVersion);
  },
} satisfies Theme;
