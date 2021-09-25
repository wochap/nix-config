{ lib, stdenv, fetchFromGitLab, cmake }:

stdenv.mkDerivation rec {
  pname = "interception-caps2esc";
  version = "1.0.0";

  src = fetchFromGitLab {
    group = "interception";
    owner = "linux/plugins";
    repo = "caps2esc";
    rev = "6ad00311380254ce6c879f08456238c52b5f44c8";
    sha256 = "0frwfzi7vdrmg2svq3saimfw287zg3s770wvb51vm9a2xc2lc124";
  };

  nativeBuildInputs = [ cmake ];

  meta = with lib; {
    homepage = "https://gitlab.com/interception/linux/plugins/caps2esc";
    description = "Transforming the most useless key ever into the most useful one";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
