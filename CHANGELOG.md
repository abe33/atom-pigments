<a name="v0.3.1"></a>
# v0.3.1 (2015-05-19)

## Bug Fixes

- Add alpha rounding after 3 decimals in palette view ([69638149](https://github.com/abe33/atom-pigments/commit/696381498dd4951aebc57fd3f6c0368e139bd59a))
- Fix accessing variables with id or name when there's no variables yet ([8155b945](https://github.com/abe33/atom-pigments/commit/8155b945f81fe834aabc99a74369670b241da96b), [#17](https://github.com/abe33/atom-pigments/issues/17))

<a name="v0.3.0"></a>
# v0.3.0 (2015-05-18)

## Features

- Add relative units for dot markers and autocomplete preview ([d3350386](https://github.com/abe33/atom-pigments/commit/d335038679f3338c3b9a26b846383b6dec988d83), [#11](https://github.com/abe33/atom-pigments/issues/11))
- Add a pigments:reload command to reload project variables ([1b3f51d6](https://github.com/abe33/atom-pigments/commit/1b3f51d6898cf2a551591bfe9e49b3d49a10978b))
  <br>As proposed in #7.
- Add node_modules as default ignored name ([e4ab734a](https://github.com/abe33/atom-pigments/commit/e4ab734ad22a0589b7d8a79ae96c650451ed1104))
  <br>As proposed in #7
- Implement rendering colors from variables only for variables sources ([fcb15da9](https://github.com/abe33/atom-pigments/commit/fcb15da97af37b2b6269aa780862ec8f22a4946d))

## Bug Fixes

- Fix attributes selectors being parsed as variables ([d7407e4c](https://github.com/abe33/atom-pigments/commit/d7407e4c291d42c80791ac17c11dce00f14ba618))

<a name="v0.2.1"></a>
# v0.2.1 (2015-05-14)

## Bug Fixes

- Fix mixins/functions arguments being parsed as variables ([e7a6fc17](https://github.com/abe33/atom-pigments/commit/e7a6fc178aa962c313ba7c3ce68301036526f093))

<a name="v0.2.0"></a>
# v0.2.0 (2015-04-30)

## Features

- Implement a delay before scanning the buffer after an input ([1ba5ee49](https://github.com/abe33/atom-pigments/commit/1ba5ee4956d81f00c5f086f0738fc2da27d89245))

## Bug Fixes

- Fix tasks still running when starting typing again ([fb185a2d](https://github.com/abe33/atom-pigments/commit/fb185a2d464212a23402d5258845af3141103a39))
- Fix provider not providing variable prefixed with $ ([f1752225](https://github.com/abe33/atom-pigments/commit/f1752225f729d84c854c728392528a3c62390134))

<a name="v0.1.4"></a>
# v0.1.4 (2015-04-24)

## Bug Fixes

- Fix invalid colors displayed in search results ([1534ea49](https://github.com/abe33/atom-pigments/commit/1534ea490ad3ccd20949f7aef7b73f5b4076a11d), [#3](https://github.com/abe33/atom-pigments/issues/3))

<a name="v0.1.3"></a>
# v0.1.3 (2015-04-23)

## Bug Fixes

- Implement strict matching in autocomplete provider ([028c3a9f](https://github.com/abe33/atom-pigments/commit/028c3a9f441d414bb3145d61a892e933920a4c61), [#3](https://github.com/abe33/atom-pigments/issues/3))
- Fix context returning invalid colors ([dc47cd1d](https://github.com/abe33/atom-pigments/commit/dc47cd1df920457215bfd2de5299c8c462a3b17a), [#4](https://github.com/abe33/atom-pigments/issues/4))

<a name="v0.1.2"></a>
# v0.1.2 (2015-04-22)

## Features

- Add json version in serialized data ([b432a50a](https://github.com/abe33/atom-pigments/commit/b432a50a82ae31ae9f6e44d532ddb3a2a0c1870b))

## Bug Fixes

- Fix invalid colors not detected by parser ([33674063](https://github.com/abe33/atom-pigments/commit/336740635241dea118972b5f914e572591fcf4bc), [#2](https://github.com/abe33/atom-pigments/issues/2))
- Fix typo in setting's name ([f9bcbd44](https://github.com/abe33/atom-pigments/commit/f9bcbd445845e1b88d346bc89c9e04f1cf0dd6a8), [#1](https://github.com/abe33/atom-pigments/issues/1))

<a name="v0.1.1"></a>
# v0.1.1 (2015-04-22)

## Bug Fixes

- Fix markers not updated after tokenization and editor styling ([ebe5a07a](https://github.com/abe33/atom-pigments/commit/ebe5a07a56a027863351dcf7422b2f45c3aa398b))
