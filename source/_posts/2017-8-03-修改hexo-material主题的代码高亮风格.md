---
title: 修改hexo-material主题的代码高亮风格
tags: ["hexo"]
categories: ["2017-08"]
date: 2017-08-03 10:41:21
---
其实比较简单，做几个填空题而已。

根据主题官网：https://material.viosey.com/expert/  的说明，
`从 1.3.0 版本开始，您可以使用 hexo-prism-plugin 进行代码染色，具体文档请参阅 Hexo-Prism-Plugin 插件文档`

转到插件文档：https://github.com/ele828/hexo-prism-plugin 

运行npm安装，根据文档，在**博客**的_config.yml中加上：
```
prism_plugin:
  mode: 'preprocess'    # realtime/preprocess
  theme: 'default'
  line_number: false    # default false
```

并且关闭自带的highlight即可。

另外所有主题的预览在这里：
https://github.com/PrismJS/prism-themes#available-themes