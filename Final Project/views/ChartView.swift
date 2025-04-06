//
//  ChartView.swift
//  Final Project
//
//  Created by Emmanuel Makoye on 4/6/25.
//


import Charts
import SwiftUI

struct ChartView: View {
    let data: ChartViewData
    @ObservedObject var vm: ChartViewModel
    
    var body: some View {
        Chart {
            ForEach(Array(zip(data.items.indices, data.items)), id: \.0) { index, item in
                LineMark(
                    x: .value("Time", index),
                    y: .value("Price", item.value)
                )
                .foregroundStyle(vm.foregroundMarkColor)
                
                AreaMark(
                    x: .value("Time", index),
                    yStart: .value("Min", data.yAxisData.axisStart),
                    yEnd: .value("Max", item.value)
                )
                .foregroundStyle(LinearGradient(
                    gradient: Gradient(colors: [vm.foregroundMarkColor, .clear]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .opacity(0.3)
                
                if let selectedX = vm.selectedXRuleMark {
                    RuleMark(x: .value("Selected timestamp", selectedX.value))
                        .lineStyle(.init(lineWidth: 1))
                        .annotation {
                            Text(selectedX.text)
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                        .foregroundStyle(vm.foregroundMarkColor)
                }
            }
        }
        .chartXAxis { chartXAxis }
        .chartXScale(domain: data.xAxisData.axisStart...data.xAxisData.axisEnd)
        .chartYAxis { chartYAxis }
        .chartYScale(domain: data.yAxisData.axisStart...data.yAxisData.axisEnd)
        .frame(height: 200)
        .chartOverlay { proxy in
            GeometryReader { gProxy in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { onChangeDrag(value: $0, chartProxy: proxy, geometryProxy: gProxy) }
                        .onEnded { _ in vm.selectedX = nil }
                    )
            }
        }
    }
    
    private var chartXAxis: some AxisContent {
        AxisMarks(values: .stride(by: data.xAxisData.strideBy)) { value in
            if let text = data.xAxisData.map[String(value.index)] {
                AxisGridLine(stroke: .init(lineWidth: 0.3))
                AxisTick(stroke: .init(lineWidth: 0.3))
                AxisValueLabel {
                    Text(text)
                        .foregroundColor(.primary)
                        .font(.caption.bold())
                }
            }
        }
    }
    
    private var chartYAxis: some AxisContent {
        AxisMarks(values: .stride(by: data.yAxisData.strideBy)) { value in
            if let y = value.as(Double.self), let text = data.yAxisData.map[y.roundedString] {
                AxisGridLine(stroke: .init(lineWidth: 0.3))
                AxisTick(stroke: .init(lineWidth: 0.3))
                AxisValueLabel {
                    Text(text)
                        .foregroundColor(.primary)
                        .font(.caption.bold())
                }
            }
        }
    }
    
    private func onChangeDrag(value: DragGesture.Value, chartProxy: ChartProxy, geometryProxy: GeometryProxy) {
        let xCurrent = value.location.x - geometryProxy[chartProxy.plotAreaFrame].origin.x
        if let index: Double = chartProxy.value(atX: xCurrent),
           index >= 0,
           Int(index) <= data.items.count - 1 {
            self.vm.selectedX = Int(index)
        }
    }
}
