class Influxdb < Formula
  desc "Time series, events, and metrics database"
  homepage "https://influxdata.com/time-series-platform/influxdb/"
  url "https://github.com/influxdata/influxdb.git",
      tag:      "v3.3.0",
      revision: "02d7ee1e6fec5b62debbe862881562e451624de6"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/influxdata/influxdb.git", branch: "main"

  # There can be a notable gap between when a version is tagged and a
  # corresponding release is created, so we check releases instead of the Git
  # tags. Upstream maintains multiple major/minor versions and the "latest"
  # release may be for an older version, so we have to check multiple releases
  # to identify the highest version.
  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :github_releases
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "577ba9284522799541c29345f9c05007fa0a4d49c506e9d6e3ef8410cf070bba"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "9cb31a2b14b041a044bb1bd8ca75a3a1799d6ab4c9981d95eafe2675cf1786fc"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "1ff048a6a4b8784a6f07c16c40a406fa90f7acc77b9f6db1d2b59403fac0d211"
    sha256 cellar: :any_skip_relocation, sonoma:        "2cbda744c82743c7e1b0193708c813b22602b65ce9c3c5117f595ea44933103e"
    sha256 cellar: :any_skip_relocation, ventura:       "5b206daf7596804851d172d0f70d0713b2477a1cc7fb58d5b0c18a3deba9a6f0"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "dce1ad38f5b09ae95904350471e1d3dd7dd9eb1558e07c52e9dda1db2dd8ab2a"
  end

  depends_on "pkgconf" => :build
  depends_on "protobuf" => :build
  depends_on "rust" => :build
  depends_on "python@3.13"

  def install
    py = Formula["python@3.13"].opt_bin/"python3"
    ENV["PYO3_PYTHON"] = py
    ENV["PYTHON_SYS_EXECUTABLE"] = py

    # Configure rpath to locate Python framework at runtime
    if OS.mac?
      fwk_dir = Formula["python@3.13"].opt_frameworks/"Python3.framework/Versions/3.13"
      ENV.append "RUSTFLAGS", "-C link-arg=-Wl,-rpath,#{fwk_dir}"
    end

    system "cargo", "install", *std_cargo_args(path: "influxdb3")
  end

  service do
    run opt_bin/"influxdb3"
    keep_alive true
    working_dir HOMEBREW_PREFIX
    log_path var/"log/influxdb3/influxd_output.log"
    error_log_path var/"log/influxdb3/influxd_output.log"
  end

  test do
    port = free_port
    host = "http://localhost:#{port}"
    pid = spawn bin/"influxdb3", "serve",
                          "--node-id", "node1",
                          "--object-store", "file",
                          "--data-dir", testpath/"influxdb_data",
                          "--http-bind", "0.0.0.0:#{port}"

    sleep 5
    sleep 5 if OS.mac? && Hardware::CPU.intel?

    curl_output = shell_output("curl --silent --head #{host}")
    assert_match "401 Unauthorized", curl_output
  ensure
    Process.kill "TERM", pid
    Process.wait pid
  end
end
