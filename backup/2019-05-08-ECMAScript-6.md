---
title: ECMAScript 6
date: 2019-05-08 11:11:44
categories: ["git"]
tags: ["git"]
toc: true
---

记录一下ECMAScript 6相关的知识点。

<!-- more -->

## Promise

```js
test = async () => {
    // return 'xxx' // in then
    // in then, add async necessary
    // return new Error('error!') 

    // in catch, add async necessary
    // throw new Error('error!') 

    // in then, add async unnecessary
    // return Promise.resolve('xxx') 

    // in catch, add async unnecessary
    // return Promise.reject(new Error('error!')) 

    // add async unnecessary
    /* return new Promise((resolve, reject) => { 
        // in then
        // resolve('yyy')
        // in catch
        // throw new Error('error!')  
        // in catch
        reject(new Error('error!')) 
    }) */
}
```

#async

```js
async fetch() {
    this.props.loadList()
    this.fetchPerson('Billy')
        // .then(this.fetchOrders)
        .then(person => this.fetchOrders(person))
        .then(orders => {
            orders.forEach(order => {
                console.log(order)
            })
        })
        .catch(console.error)
    // let person = await this.fetchPerson('Billy')
    // let orders = await this.fetchOrders(person)
    // orders.forEach(order => {
    //     console.log(order)
    // })
}

// call
this.test().then(
    x => {
        alert('x->' + x)
    }/* ,
    err => {
        alert('e->' + err)
    } */
    // catch与then中的第二个参数效果一样
    ).catch(err => {
        alert('e->' + err)
    })
)

async fetchOrders(person) {
    const orders = person.orderIds.map(id => ({ id }))
    return orders
}

async fetchPerson(name) {
    return {
        name,
        orderIds: ['A', 'B']
    }
}
```

## 参考

- https://dvajs.com/knowledgemap/#javascript-%E8%AF%AD%E8%A8%80
- https://es6.ruanyifeng.com/
- https://ithelp.ithome.com.tw/articles/10201276
- https://ithelp.ithome.com.tw/articles/10201420?sc=iThelpR