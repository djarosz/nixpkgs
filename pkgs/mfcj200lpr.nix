{ stdenv, fetchurl, cups, dpkg, pkgsi686Linux, ghostscript, a2ps, coreutils,  gnused, gawk, file, makeWrapper, runtimeShell }:

let
  model = "mfcj200";
in
pkgsi686Linux.stdenv.mkDerivation rec {
  pname = "${model}lpr";
  version = "3.0.0-1";

  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf100919/${pname}-${version}.i386.deb";
    sha256 = "aa7673cf5249a5331f86de2971f06364c92a28ac9af9a5cc9198408d1b41a6e1";
  };

  nativeBuildInputs = [ makeWrapper dpkg ];
  buildInputs = [ cups ghostscript a2ps gnused ];

  dontUnpack = true;
  nopatchElf = true;

  brprintconf_script = ''
    #!${runtimeShell}
    cd $(mktemp -d)
    ln -s @out@/usr/bin/brprintconf_${model}_patched brprintconf_${model}_patched
    ln -s @out@/opt/brother/Printers/${model}/inf/br${model}func br${model}func
    ln -s @out@/opt/brother/Printers/${model}/inf/br${model}rc br${model}rc
    ./brprintconf_${model}_patched "$@"
  '';

  installPhase = ''
    dpkg-deb -x $src $out

    FILE=$out/opt/brother/Printers/${model}/lpd/filter${model}
    substituteInPlace $FILE \
      --replace /opt "$out/opt"
    wrapProgram $FILE \
      --run "cd $out" \
      --prefix PATH ":" ${ stdenv.lib.makeBinPath [ ghostscript a2ps file gnused coreutils ] }

    FILE=$out/opt/brother/Printers/${model}/lpd/psconvertij2
    sed -i -e 's/^GHOST_SCRIPT=.*/GHOST_SCRIPT=gs/' $FILE
    wrapProgram $FILE \
      --run "cd $out" \
      --prefix PATH ":" ${ stdenv.lib.makeBinPath [ ghostscript gnused coreutils gawk ] }

    FILE=$out/opt/brother/Printers/${model}/inf/setupPrintcapij
    substituteInPlace $FILE \
      --replace /opt "$out/opt" \
      --replace /etc/printcap.local /etc/printcap
    wrapProgram $FILE \
      --run "cd $out" \
      --prefix PATH ":" ${ stdenv.lib.makeBinPath [ gnused coreutils ] }

    FILE=$out/opt/brother/Printers/${model}/lpd/br${model}filter
    sed -i -e 's./opt/.opt//.g' $FILE 
    patchelf --set-interpreter ${pkgsi686Linux.stdenv.cc.libc.out}/lib/ld-linux.so.2 $FILE

    FILE=$out/usr/bin/brprintconf_${model}
    PATCHED=$out/usr/bin/brprintconf_${model}_patched
    sed 's#/opt/brother/Printers/%s/inf/br%sfunc#.///////////////////////br${model}func#' $FILE | \
     sed 's#/opt/brother/Printers/%s/inf/br%src#.///////////////////////br${model}rc#' > $PATCHED
    patchelf --set-interpreter ${pkgsi686Linux.stdenv.cc.libc.out}/lib/ld-linux.so.2 $PATCHED
    chmod +x $PATCHED
    # executing from current dir. does not apply print settings if it's not r\w.
    echo -n "$brprintconf_script" > $FILE
    chmod +x $FILE
    substituteInPlace $FILE --replace @out@ $out

    '';

  meta = {
    homepage = "http://www.brother.com/";
    description = "Brother ${model} LPR driver";
    license = stdenv.lib.licenses.unfree;
    platforms = stdenv.lib.platforms.linux;
    downloadPage = "http://support.brother.com/g/b/downloadlist.aspx?c=us&lang=en&prod=${model}_us_eu_as&os=128";
    maintainers = [ "dawid.jarosz@gmail.com" ];
  };
}
