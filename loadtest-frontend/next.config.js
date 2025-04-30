const nextConfig = {
  reactStrictMode: true,
  output: "export",
  trailingSlash: true,
  images: {
    unoptimized: true,
  },
  exportPathMap: async function () {
    return {
      "/": { page: "/" },
      "/register": { page: "/register" },
      "/login": { page: "/login" },
      "/profile": { page: "/profile" },
      "/chat-rooms": { page: "/chat-rooms" },
      "/chat-rooms/new": { page: "/chat-rooms/new" },
    };
  },
};

module.exports = nextConfig;
