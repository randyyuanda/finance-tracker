import { useSelector } from 'react-redux';
import translations from './translations';

export default function useT() {
  const language = useSelector((s) => s.settings.language);
  const dict = translations[language] || translations.en;
  return (key) => dict[key] ?? translations.en[key] ?? key;
}
