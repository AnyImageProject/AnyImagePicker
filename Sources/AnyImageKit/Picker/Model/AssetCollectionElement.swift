//
//  AssetCollectionElement.swift
//  AnyImageKit
//
//  Created by 刘栋 on 2021/5/6.
//  Copyright © 2021 AnyImageProject.org. All rights reserved.
//

import Foundation

public enum AssetCollectionElement<Element: IdentifiableResource>: Equatable {
    
    case prefixAddition(AssetCollectionAddition)
    case asset(Element)
    case suffixAddition(AssetCollectionAddition)
}

extension AssetCollectionElement {
    
    public var asset: Element? {
        switch self {
        case .asset(let asset):
            return asset
        default:
            return nil
        }
    }
}

extension AssetCollectionElement {
    
    public var addition: AssetCollectionAddition? {
        switch self {
        case .prefixAddition(let addition), .suffixAddition(let addition):
            return addition
        default:
            return nil
        }
    }
    
    public var prefixAddition: AssetCollectionAddition? {
        switch self {
        case .prefixAddition(let addition):
            return addition
        default:
            return nil
        }
    }
    
    public var suffixAddition: AssetCollectionAddition? {
        switch self {
        case .suffixAddition(let addition):
            return addition
        default:
            return nil
        }
    }
}