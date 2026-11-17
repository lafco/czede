// O ícone do app, como o GitHub mostra o czede, qualquer que seja o canal.
import appIconUrl from "../../../../assets/czede/czede-web-apple-touch-180.png";

export function CzedeAppIcon(props: { readonly className?: string }) {
  return <img src={appIconUrl} alt="" className={props.className} />;
}
