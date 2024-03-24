{ pkgs, python3Packages, fetchurl }:

with python3Packages;
buildPythonPackage rec {
  pname = "bt-dualboot";
  version = "1.0.1";
  src = fetchurl {
    url =
      "https://files.pythonhosted.org/packages/42/82/c3e1bfca558d8a5f7dd51183ba0f1a3d2061f5442bfa54821398bb3813b8/bt_dualboot-1.0.1-py3-none-any.whl";
    sha256 = "0808abhaab0ml1rqicqp61y2i5qn905diyccn0c4k98i95mc97kp";
  };
  format = "wheel";
  doCheck = false;
  buildInputs = [ ];
  checkInputs = [ ];
  nativeBuildInputs = [ ];
  propagatedBuildInputs = with pkgs; [ chntpw ];
}
