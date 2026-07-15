import Image from "next/image";
import idealLogo from "../../images/ideal-logo.png";

export function Logo() {
  return (
    <div className="flex items-center gap-3">
      <Image
        src={idealLogo}
        width={44}
        height={44}
        alt="IDEAL"
        className="rounded-xl"
        quality={100}
      />
      <span className="text-2xl font-bold tracking-normal text-dark dark:text-white">
        IDEAL
      </span>
    </div>
  );
}
