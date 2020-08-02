{ stdenv, psutils, fetchurl, mfcj200lpr, makeWrapper, gnused, gnugrep, coreutils, dpkg, pkgsi686Linux }:

let
  model = "mfcj200";
in
pkgsi686Linux.stdenv.mkDerivation rec {
  name = "${model}cupswrapper-${meta.version}";

  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf100921/${name}.i386.deb";
    sha256 = "6eed1b268b8652685c9ee26cf5b8dd55574c2b8084fca6792a1c09cfc6ccce7d";
  };

  nativeBuildInputs = [ dpkg makeWrapper ];
  buildInputs = [ mfcj200lpr ];

  dontUnpack = true;
  nopatchElf = true;

  installPhase = ''
    dpkg-deb -x $src $out

    mkdir -p $out/lib/cups/filter
    mkdir -p $out/share/cups/model

    FILE=$out/lib/cups/filter/brother_lpdwrapper_${model}
    cp $out/opt/brother/Printers/${model}/cupswrapper/cupswrapper${model} $FILE
    sed -i -e '110,261!d' $FILE
    substituteInPlace $FILE \
      --replace "$``{device_model``}" "Printers" \
      --replace "$``{printer_model``}" "${model}" \
      --replace "$``{printer_name``}" "${model}" \
      --replace "/opt/brother/Printers/${model}/lpd/filter${model}" \
        "${mfcj200lpr}/opt/brother/Printers/${model}/lpd/filter${model}" \
      --replace "/opt/brother/Printers/${model}/inf/br${model}rc" \
        "${mfcj200lpr}/opt/brother/Printers/${model}/inf/br${model}rc" \
      --replace "/opt/brother/Printers/${model}/cupswrapper/brcupsconfpt1" \
        "$out/opt/brother/Printers/${model}/cupswrapper/brcupsconfpt1" \
      --replace "/usr/share/cups/model/Brother/brother_" \
        "$out/opt/brother/Printers/${model}/cupswrapper/brother_" \
      --replace '/usr/bin/psnup' '${psutils}/bin/psnup' \
      --replace '\$' '$' \
      --replace '\`' '`'
    wrapProgram $FILE \
      --prefix PATH ":" ${stdenv.lib.makeBinPath [ coreutils gnused gnugrep ] }

    ln $out/opt/brother/Printers/${model}/cupswrapper/brother_${model}_printer_en.ppd $out/share/cups/model/brother_${model}_printer_en.ppd

    FILE=$out/opt/brother/Printers/${model}/cupswrapper/brcupsconfpt1
    patchelf --set-interpreter ${pkgsi686Linux.stdenv.cc.libc.out}/lib/ld-linux.so.2 $FILE
    '';

  meta = {
    homepage = "http://www.brother.com/";
    description = "Brother MFC-J200 CUPS wrapper driver";
    license = stdenv.lib.licenses.gpl2;
    platforms = stdenv.lib.platforms.linux;
    downloadPage = "http://support.brother.com/g/b/downloadlist.aspx?c=us&lang=en&prod=${model}_us_eu_as&os=128";
    maintainers = [ "dawid.jarosz@gmail.com" ];
    version = "3.0.0-1";
  };
}
