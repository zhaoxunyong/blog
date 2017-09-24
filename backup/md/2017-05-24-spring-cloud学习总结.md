---
title: spring cloud学习总结
date: 2017-05-24 10:48:46
tags:
toc: true
---


<!-- more -->
## Feign

### Feign与Hystrix的问题：
加载顺序：
@Component > @Configuration
Construct function > @PostConstruct

如果@Bean的类型是static的话，会忽略@Order或者@AutoConfigureOrder，会优先加载：
```java
@Bean
Request.Options feignOptions() {
    return new Request.Options();
}
```

Request.Options是一个static class

如果都有配置@Configuration的话，spring.factories中的@Configuration会在项目的@Configuration之后再加载。不能通过@AutoConfigureOrder定义加载顺序。

## Zipkin

### http方式

### mq方式

## Config