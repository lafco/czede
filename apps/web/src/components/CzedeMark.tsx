import type { SVGProps } from "react";

/**
 * Marca do czede em um só tom (`currentColor`), para usar em qualquer tamanho:
 * marca do sidebar, ícone de atividade e cabeçalho de página standalone. É a
 * mesma geometria do ícone de app (cubo isométrico com tiers no topo), sem os
 * gradientes — no UI ela precisa herdar a cor do texto.
 */
export function CzedeMark(props: SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="-50 -50 100 100" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
      <path d="M-41.568 -24 L0 0 L0 48 L-41.568 24 Z" fill="currentColor" fillOpacity="0.5" />
      <path d="M0 0 L41.568 -24 L41.568 24 L0 48 Z" fill="currentColor" fillOpacity="0.68" />
      <path d="M0 -48 L41.568 -24 L0 0 L-41.568 -24 Z" fill="currentColor" fillOpacity="0.88" />
      <path
        d="M0 -37.92 L24.109 -24 L0 -10.08 L-24.109 -24 Z"
        fill="currentColor"
        fillOpacity="0.55"
      />
      <path d="M0 -32.64 L14.964 -24 L0 -15.36 L-14.964 -24 Z" fill="currentColor" />
      <g stroke="currentColor" strokeWidth="3" strokeLinejoin="round" strokeLinecap="round">
        <path d="M0 -48 L-41.568 -24 L0 0 L41.568 -24 Z" />
        <path d="M-41.568 -24 L-41.568 24 L0 48 L41.568 24 L41.568 -24" />
        <path d="M0 0 L0 48" />
      </g>
    </svg>
  );
}
