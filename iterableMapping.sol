pragma solidity ^0.7.6;

library IterableMapping {
    // Iterable mapping from address to uint
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        // 获取删除 key 对应下标
        uint index = map.indexOf[key];
        // 获取当前 keys 的长度
        uint lastIndex = map.keys.length - 1;
        // 获取 keys 数组最后一个元素
        address lastKey = map.keys[lastIndex];
        // 将当前删除 key 的下标移到最后
        map.indexOf[lastKey] = index;
        delete map.indexOf[key];
        // 将原先获取最后的 keys 数组元素放到删除位置上
        map.keys[index] = lastKey;
        // 移除最后一个元素，因为上一步已将它挪到删除地方了
        map.keys.pop();
    }
}

contract TestIterableMap {
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private map;

    function testIterableMap() public {
        map.set(address(0), 0);
        map.set(address(1), 100);
        map.set(address(2), 200);
        map.set(address(2), 200);
        map.set(address(3), 300);

        for (uint i = 0; i < map.size(); i++) {
            // 先获取下标对应的地址
            address key = map.getKeyAtIndex(i);
            // 通过地址值获取对应的 value
            assert(map.get(key) == i * 100);
        }

        map.remove(address(1));

        // keys = [address(0), address(3), address(2)]
        assert(map.size() == 3);
        assert(map.getKeyAtIndex(0) == address(0));
        assert(map.getKeyAtIndex(1) == address(3));
        assert(map.getKeyAtIndex(2) == address(2));
    }
}