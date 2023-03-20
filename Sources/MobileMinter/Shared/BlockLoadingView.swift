//
//  BlockLoadingView.swift
//  MobileMinter
//
//  Created by Shantanu Bala on 11/16/22.
//

import SwiftUI

struct ColoredBlock: View {
  var color: Color

  var body: some View {
    if color != Color.clear {
      Rectangle().fill(color)
        .frame(
          width: 120, height: 120, alignment: /*@START_MENU_TOKEN@*/ .center /*@END_MENU_TOKEN@*/
        )
        .mask(Image("cube"))
        .overlay(Image("cube").opacity(color == Color(.clear) ? 0 : 0.125))
    } else {
      EmptyView()
    }
  }
}

enum SetOfSixBlocks: CaseIterable {

  static var indexOffset: Int = 0

  case one, two, three, four, five, clear

  var view: some View {
    switch self {
    case .one:
      return ColoredBlock(color: Color.red)
    case .two:
      return ColoredBlock(color: Color.orange)
    case .three:
      return ColoredBlock(color: Color.yellow)
    case .four:
      return ColoredBlock(color: Color.green)
    case .five:
      return ColoredBlock(color: Color.blue)
    default:
      return ColoredBlock(color: Color.clear)
    }
  }
}

struct SixBlockAnimation: View {
  @State var allBlocks = SetOfSixBlocks.allCases
  @State var allIndices: [(CGFloat, CGFloat, Double, Bool)] = [
    (-80, 40, 5, true),
    (-40, 20, 3, false),
    (0, 0, 1, false),
    (40, 20, 2, true),
    (0, 40, 4, false),
    (-40, 60, 6, false),
  ]
  @State var currentIndex: Int = 4
  let progress: Int
  let offset: Int

  var body: some View {
    ZStack {
      ForEach(stride(from: 0, to: allBlocks.count, by: 1).sorted(), id: \.self) { index in
        cube(index: index, offset: offset)
      }
    }
    .onAppear {
      withAnimation(Animation.spring()) {
        rotate()
      }
    }
  }

  func cube(index: Int, offset: Int) -> some View {
    let offset = allIndices[(index + offset) % allIndices.count]
    return allBlocks[index].view
      .offset(x: offset.0, y: offset.1)
      .zIndex(offset.2)
  }

  func rotate() {
    let clearPosition = allIndices[5]

    allIndices[5] = allIndices[currentIndex]
    allIndices[currentIndex] = clearPosition

    currentIndex = currentIndex - 1

    if currentIndex == -1 {
      currentIndex = 4
    }

    DispatchQueue.main.asyncAfter(
      deadline: .now() + (0.5 + Double(arc4random()) / Double(UINT32_MAX))
        * (4.2 / Double(offset + 1))
    ) {
      withAnimation(Animation.spring()) {
        rotate()
      }
    }

  }
}

struct BlockLoadingView: View {
  let progress: Int
  var body: some View {
    ZStack {
      Group {
        ZStack {
          SixBlockAnimation(progress: progress, offset: 0).offset(x: 0, y: -120)
          SixBlockAnimation(progress: progress, offset: 2)
          SixBlockAnimation(progress: progress, offset: 1).offset(x: 0, y: 120)
        }
        ZStack {
          SixBlockAnimation(progress: progress, offset: 1).offset(x: 0, y: -120)
          SixBlockAnimation(progress: progress, offset: 2)
          SixBlockAnimation(progress: progress, offset: 2).offset(x: 0, y: 120)
        }.offset(x: -120, y: 60)
        ZStack {
          SixBlockAnimation(progress: progress, offset: 2).offset(x: 0, y: -120)
          SixBlockAnimation(progress: progress, offset: 0)
          SixBlockAnimation(progress: progress, offset: 1).offset(x: 0, y: 120)
        }.offset(x: -240, y: 120)
      }.offset(x: 360, y: -180)
      Group {
        ZStack {
          SixBlockAnimation(progress: progress, offset: 1).offset(x: 0, y: -120)
          SixBlockAnimation(progress: progress, offset: 2)
          SixBlockAnimation(progress: progress, offset: 1).offset(x: 0, y: 120)
        }
        ZStack {
          SixBlockAnimation(progress: progress, offset: 1).offset(x: 0, y: -120)
          SixBlockAnimation(progress: progress, offset: 2)
          SixBlockAnimation(progress: progress, offset: 2).offset(x: 0, y: 120)
        }.offset(x: -120, y: 60)
        ZStack {
          SixBlockAnimation(progress: progress, offset: 2).offset(x: 0, y: -120)
          SixBlockAnimation(progress: progress, offset: 0)
          SixBlockAnimation(progress: progress, offset: 0).offset(x: 0, y: 120)
        }.offset(x: -240, y: 120)
        Group {
          ZStack {
            SixBlockAnimation(progress: progress, offset: 0).offset(x: 0, y: -120)
            SixBlockAnimation(progress: progress, offset: 2)
            SixBlockAnimation(progress: progress, offset: 1).offset(x: 0, y: 120)
          }
          ZStack {
            SixBlockAnimation(progress: progress, offset: 1).offset(x: 0, y: -120)
            SixBlockAnimation(progress: progress, offset: 1)
            SixBlockAnimation(progress: progress, offset: 2).offset(x: 0, y: 120)
          }.offset(x: -120, y: 60)
          ZStack {
            SixBlockAnimation(progress: progress, offset: 2).offset(x: 0, y: -120)
            SixBlockAnimation(progress: progress, offset: 0)
            SixBlockAnimation(progress: progress, offset: 1).offset(x: 0, y: 120)
          }.offset(x: -240, y: 120)
        }.offset(x: -360, y: 180)
      }
    }.offset(x: 0, y: 180)
  }
}

struct BlockLoadingView_Previews: PreviewProvider {
  static var previews: some View {
    BlockLoadingView(progress: 0)
  }
}
