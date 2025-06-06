import Foundation

protocol GenericVariableMixable: RawRepresentableString {
    /// Soil moisture or snow depth are cumulative processes and have offests if mutliple models are mixed
    var requiresOffsetCorrectionForMixing: Bool { get }
}

/// Mix differnet domains together, that offer the same or similar variable set
protocol GenericReaderMixerRaw: GenericReaderProtocol {
    associatedtype Reader: GenericReaderProtocol

    var reader: [Reader] { get }
    init(reader: [Reader])
}

protocol GenericReaderMixer: GenericReaderMixerRaw {
    associatedtype Domain: GenericDomain

    static func makeReader(domain: Domain, lat: Float, lon: Float, elevation: Float, mode: GridSelectionMode, options: GenericReaderOptions) async throws -> Reader?
}

struct GenericReaderMixerSameDomain<Reader: GenericReaderProtocol>: GenericReaderMixerRaw, GenericReaderProtocol {
    typealias MixingVar = Reader.MixingVar

    let reader: [Reader]
}

extension GenericReaderMixer {
    public init?(domains: [Domain], lat: Float, lon: Float, elevation: Float, mode: GridSelectionMode, options: GenericReaderOptions) async throws {
        /// Initiaise highest resolution domain first. If `elevation` is NaN, use the elevation of the highest domain,
        var elevation = elevation

        let reader: [Reader] = try await domains.reversed().asyncCompactMap { domain -> (Reader?) in
            guard let domain = try await Self.makeReader(domain: domain, lat: lat, lon: lon, elevation: elevation, mode: mode, options: options) else {
                return nil
            }
            if elevation.isNaN {
                elevation = domain.modelElevation.numeric
            }
            return domain
        }.reversed()

        guard !reader.isEmpty else {
            return nil
        }
        self.init(reader: reader)
    }
}

extension GenericReaderMixerRaw {
    var modelLat: Float {
        reader.last!.modelLat
    }
    var modelLon: Float {
        reader.last!.modelLon
    }
    var modelElevation: ElevationOrSea {
        reader.last!.modelElevation
    }
    var targetElevation: Float {
        reader.last!.targetElevation
    }
    var modelDtSeconds: Int {
        reader.last!.modelDtSeconds
    }

    func prefetchData(variable: Reader.MixingVar, time: TimerangeDtAndSettings) async throws {
        for reader in reader {
            try await reader.prefetchData(variable: variable, time: time)
        }
    }

    func prefetchData(variables: [Reader.MixingVar], time: TimerangeDtAndSettings) async throws {
        for variable in variables {
            try await prefetchData(variable: variable, time: time)
        }
    }

    func getStatic(type: ReaderStaticVariable) async throws -> Float? {
        return try await reader.last?.getStatic(type: type)
    }

    func get(variable: Reader.MixingVar, time: TimerangeDtAndSettings) async throws -> DataAndUnit {
        // Last reader return highest resolution data. therefore reverse iteration
        // Integrate now lower resolution models
        var data: [Float]?
        var unit: SiUnit?
        if variable.requiresOffsetCorrectionForMixing {
            for r in reader.reversed() {
                let d = try await r.get(variable: variable, time: time)
                if data == nil {
                    // first iteration
                    data = d.data
                    unit = d.unit
                    data?.deltaEncode()
                } else {
                    data?.integrateIfNaNDeltaCoded(d.data)
                }
                if data?.containsNaN() == false {
                    break
                }
            }
            // undo delta operation
            data?.deltaDecode()
            data?.greater(than: 0)
        } else {
            // default case, just place new data in 1:1
            for r in reader.reversed() {
                let d = try await r.get(variable: variable, time: time)
                if data == nil {
                    // first iteration
                    data = d.data
                    unit = d.unit
                } else {
                    data?.integrateIfNaN(d.data)
                }
                if data?.containsNaN() == false {
                    break
                }
            }
        }
        guard let data, let unit else {
            fatalError("Expected data in mixer for variable \(variable)")
        }
        return DataAndUnit(data, unit)
    }
}

extension VariableOrDerived: GenericVariableMixable where Raw: GenericVariableMixable, Derived: GenericVariableMixable {
    var requiresOffsetCorrectionForMixing: Bool {
        switch self {
        case .raw(let raw):
            return raw.requiresOffsetCorrectionForMixing
        case .derived(let derived):
            return derived.requiresOffsetCorrectionForMixing
        }
    }
}

extension Array where Element == Float {
    mutating func integrateIfNaN(_ other: [Float]) {
        for x in other.indices {
            if other[x].isNaN || !self[x].isNaN {
                continue
            }
            self[x] = other[x]
        }
    }
    mutating func integrateIfNaNDeltaCoded(_ other: [Float]) {
        for x in other.indices {
            if other[x].isNaN || !self[x].isNaN {
                continue
            }
            if x > 0 {
                self[x] = other[x - 1] - other[x]
            } else {
                self[x] = other[x]
            }
        }
    }
}
