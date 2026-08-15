import { useLocalSearchParams } from 'expo-router';
import MirrorScreen from '@/src/mirror/MirrorScreen';
export default function AdminCarMediaRoute() {
  const params = useLocalSearchParams<{ id?: string | string[] }>();
  const raw = Array.isArray(params.id) ? params.id[0] : params.id;
  const id = raw ? encodeURIComponent(raw) : '';
  return <MirrorScreen path={`/admin/cars/edit/?id=${id}`} />;
}
