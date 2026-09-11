class Icebug < Formula
  desc "High-performance graph analytics backed by read-only memory"
  homepage "https://github.com/Ladybug-Memory/icebug"
  url "https://github.com/Ladybug-Memory/icebug/archive/refs/tags/13.3.tar.gz"
  sha256 "28acfdf7ae257d96fe30f6ea8f85db4b86b45d81281b3e8ccb7d321fe9f8457b"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "cmake" => :build
  depends_on "cython" => :build
  depends_on "ninja" => :build
  depends_on "python-setuptools" => :build
  depends_on "tlx" => :build

  depends_on "apache-arrow"
  depends_on "numpy"
  depends_on "python@3.14"
  depends_on "scipy"

  on_macos do
    depends_on "libomp"
  end

  def install
    site_packages = Language::Python.site_packages(python3)

    ENV.prepend_create_path "PYTHONPATH", prefix/site_packages
    ENV.append_path "PYTHONPATH", formula_opt_libexec("cython")/site_packages

    networkit_site_packages = prefix/site_packages/"networkit"
    extra_rpath = rpath(source: networkit_site_packages, target: formula_opt_lib("apache-arrow"))
    system python3, "setup.py", "build_ext", "--external-tlx=#{formula_opt_prefix("tlx")}",
                                             "--rpath=#{loader_path};#{extra_rpath}"

    system python3, "-m", "pip", "install", *std_pip_args, "."
  end

  test do
    system python3, "-c", <<~PYTHON
      import icebug as ib
      G = ib.graph.Graph(3)
      G.addEdge(0,1)
      G.addEdge(1,2)
      G.addEdge(2,0)
      assert G.degree(0) == 2
      assert G.degree(1) == 2
      assert G.degree(2) == 2
    PYTHON
  end
end
