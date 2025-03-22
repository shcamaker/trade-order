class Config {
  // 更可靠地检测生产环境
  static bool get isProduction {
    // 检查是否为release模式
    const bool isReleaseMode = bool.fromEnvironment('dart.vm.product');
    
    // 检查是否为桌面应用
    const bool isDesktopApp = !bool.fromEnvironment('dart.vm.debug', defaultValue: true);
    
    // 添加标志，允许手动覆盖环境设置
    const bool forceProduction = bool.fromEnvironment('FORCE_PRODUCTION', defaultValue: false);
    
    // 对于桌面应用和release版本，总是使用生产环境
    return isReleaseMode || isDesktopApp || forceProduction;
  }

  // API 基础URL
  static String get baseUrl {
    if (isProduction) {
      return 'http://8.138.99.79'; // 阿里云部署的API地址
    }
    return 'http://localhost:8000';
  }

  // API 超时设置
  static const Duration apiTimeout = Duration(seconds: 30);

  // GitHub Pages 部署的基础路径
  static String get baseHref {
    if (isProduction) {
      return '/trade-order/';
    }
    return '/';
  }
}
