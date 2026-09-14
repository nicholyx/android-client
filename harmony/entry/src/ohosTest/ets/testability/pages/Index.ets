@Entry
@Component
struct Index {
  @State message: string = 'NetBird Test Ability';

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
    }
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
