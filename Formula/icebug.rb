class Icebug < Formula
  desc "High-performance graph analytics backed by read-only memory"
  homepage "https://github.com/Ladybug-Memory/icebug"
  url "https://github.com/Ladybug-Memory/icebug/archive/refs/tags/13.5.tar.gz"
  sha256 "687888f1575d0cedb5ada74f31f667bd69b71a676fe53efcaf0cfd5f829de077"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "cmake" => :build
  depends_on "llvm" => :build
  depends_on "apache-arrow"
  depends_on "tlx"
  depends_on "ttmath"

  on_macos do
    depends_on "libomp"
  end

  def install
    # Build with Homebrew's LLVM clang rather than Xcode's AppleClang,
    # so a plain Command Line Tools install is sufficient.
    ENV["CC"] = Formula["llvm"].opt_bin/"clang"
    ENV["CXX"] = Formula["llvm"].opt_bin/"clang++"

    args = [
      "-DNETWORKIT_EXT_TLX=#{formula_opt_prefix("tlx")}",
      "-DNETWORKIT_CXX_STANDARD=20",
    ]
    # Upstream's CMake fallback only searches /usr for libomp when the
    # compiler is brew clang, so point it at the libomp formula explicitly.
    if OS.mac?
      args += [
        "-DOpenMP_CXX_FLAGS=-fopenmp -I#{formula_opt_include("libomp")}",
        "-DOpenMP_CXX_LIB_NAMES=omp",
        "-DOpenMP_omp_LIBRARY=#{formula_opt_lib("libomp")}/libomp.dylib",
      ]
    end

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    # `cmake --install` only ships *.hpp headers, so install the remaining
    # *.tpp implementation files included by the public headers.
    Dir["include/networkit/**/*.tpp"].each do |header|
      (include/File.dirname(header.delete_prefix("include/"))).install header
    end
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <networkit/graph/Graph.hpp>
      int main()
      {
        // Try to create a graph with five nodes
        NetworKit::Graph g(5);
        return 0;
      }
    CPP
    flags = %W[-I#{formula_opt_include("apache-arrow")} -I#{formula_opt_include("tlx")}"]
    flags << "-I#{formula_opt_include("libomp")}" if OS.mac?
    system ENV.cxx, "-std=c++20", "test.cpp", "-L#{lib}", "-lnetworkit", "-o", "test", *flags
    system "./test"
  end
end
