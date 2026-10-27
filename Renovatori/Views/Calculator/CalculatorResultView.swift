import SwiftUI

/// Result of `POST /calculator` (`views/pages/calculator-result-page`):
/// the client total, price per m², what the money pays for, and the entered parameters.
struct CalculatorResultView: View {
    let submission: CalculatorSubmission

    private var result: CalculationResult { submission.result }
    private var request: CalculationRequest { submission.request }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                totalCard
                breakdownCard
                parametersCard
                callToAction
            }
            .padding()
        }
        .navigationTitle("შედეგი")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var totalCard: some View {
        VStack(spacing: 8) {
            Text("თქვენი რემონტის სავარაუდო ღირებულება")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .opacity(0.8)
            Text(result.clientTotal.lariFormatted)
                .font(.system(.largeTitle, design: .rounded).bold())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("1 მ²-ის ფასი: \(result.clientPricePerArea.lariFormatted)")
                .font(.subheadline)
                .opacity(0.85)
            Label("მიახლოებითი შეფასებაა — ზუსტ ფასს ადგილზე უფასო დათვალიერების შემდეგ დაგიდასტურებთ.", systemImage: "info.circle")
                .font(.footnote)
                .opacity(0.8)
                .padding(.top, 4)
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(.white)
        .padding(.vertical, 24)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var breakdownCard: some View {
        GroupBox {
            if result.breakdown.isEmpty {
                Text("დეტალური ჩაშლა მიუწვდომელია.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 14) {
                    ForEach(result.breakdown) { item in
                        BreakdownRow(item: item)
                    }
                    Divider()
                    HStack {
                        Text("ჯამი")
                            .font(.subheadline.bold())
                        Spacer()
                        Text(result.clientTotal.lariFormatted)
                            .font(.subheadline.bold().monospacedDigit())
                    }
                }
                .padding(.top, 8)
            }
        } label: {
            Label("რაში იხდით თანხას", systemImage: "list.bullet.rectangle")
        }
    }

    private var parametersCard: some View {
        GroupBox {
            VStack(spacing: 10) {
                ParameterRow(title: "ბინის ფართობი", value: area(result.info.totalArea ?? request.totalArea))
                ParameterRow(title: "ოთახები", value: "\(request.rooms.count)")
                ParameterRow(title: "აბაზანა", value: "\(request.bathrooms.count)")
                if let walls = result.info.wallsTotalArea {
                    ParameterRow(title: "კედლები", value: area(walls))
                }
                ParameterRow(title: "ჭერის სიმაღლე", value: "\(request.height.compactFormatted) სმ")
                ParameterRow(title: "ჭერის ტიპი", value: ceilingSummary)
                ParameterRow(title: "იატაკის ტიპი", value: floorSummary)
                ParameterRow(title: "MDF-ის კარი", value: "\(request.doors)")
                ParameterRow(title: "ბოილერი (გათბობის ქვები)", value: "\(request.boilers)")
                ParameterRow(title: "სველი წერტილები", value: "\(request.wetAreas)")
                ParameterRow(
                    title: "ელექტრო წერტილები",
                    value: (result.info.electricalPoints ?? electricalPointsTotal).compactFormatted
                )
                ParameterRow(title: "სართული", value: request.floor.map(String.init) ?? "-")
                ParameterRow(
                    title: "ლიფტი",
                    value: request.elevator.flatMap(CalculatorForm.Elevator.init(rawValue:))?.title ?? "-"
                )
            }
            .padding(.top, 8)
        } label: {
            Label("თქვენი პარამეტრები", systemImage: "slider.horizontal.3")
        }
    }

    private var callToAction: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("მზად ხართ რემონტის დასაწყებად?")
                .font(.headline)
            Text("დაჯავშნეთ უფასო კონსულტაცია და მიიღეთ ზუსტი შეფასება ჩვენი სპეციალისტისგან.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                NavigationLink(value: AppRoute.consultation) {
                    Label("კონსულტაციის დაჯავშნა", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                ContactButton(action: .call) {
                    Label("დაგვიკავშირდით", systemImage: "phone")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.regular)
            .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func area(_ value: Double) -> String {
        "\(value.compactFormatted) მ²"
    }

    private var ceilingSummary: String {
        let ceilings = request.rooms.map(\.ceilingType)
        let french = ceilings.filter { $0 == CalculatorForm.CeilingType.french.rawValue }.count
        return "\(french) გასაჭიმი, \(ceilings.count - french) თაბაშირ მუყაო"
    }

    private var floorSummary: String {
        let laminate = request.rooms.filter { $0.floorType == CalculatorForm.FloorType.laminate.rawValue }.count
        return "\(laminate) ლამინატი, \(request.rooms.count - laminate) მეტლახი/გრანიტი"
    }

    private var electricalPointsTotal: Double {
        request.rooms.map(\.electricalPoints).reduce(0, +) + request.bathrooms.map(\.electricalPoints).reduce(0, +)
    }
}

private struct BreakdownRow: View {
    let item: CalculationResult.BreakdownItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Label(item.label, systemImage: item.symbolName)
                    .font(.subheadline)
                Spacer(minLength: 8)
                Text(item.amount.lariFormatted)
                    .font(.subheadline.monospacedDigit())
            }
            HStack(spacing: 8) {
                ProgressView(value: min(max(item.percent, 0), 100), total: 100)
                Text("\(item.percent.formatted(.number.precision(.fractionLength(0...1))))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 44, alignment: .trailing)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ParameterRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
            Spacer(minLength: 8)
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
