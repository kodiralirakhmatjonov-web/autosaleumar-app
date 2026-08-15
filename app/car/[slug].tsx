import { useLocalSearchParams } from 'expo-router';
import MirrorScreen from '@/src/mirror/MirrorScreen';
export default function CarRoute() {
  const params = useLocalSearchParams<{ slug?: string | string[] }>();
  const raw = Array.isArray(params.slug) ? params.slug[0] : params.slug;
  const slug = raw ? encodeURIComponent(raw) : '';
  return <MirrorScreen path={`/car/?slug=${slug}`} />;
}
