mergeInto(LibraryManager.library, {
	/**
	 * union isa_t {
	 *   Class cls;
	 *   uintptr_t bits;
	 * }
	 * struct objc_object {
	 *   isa_t isa;
	 * }
	 * struct bucket_t {
	 *   cache_key_t _key;          // cache_key_t = uintptr_t
	 *   IMP _imp;                  // IMP = (*func)(self, sel, ...)
	 * }
	 * struct cache_t {
	 *   struct bucket_t *_buckets;
	 *   mask_t _mask;              // mask_t = uint16_t
	 *   mask_t _occupied;
	 * }
	 * struct objc_class : objc_object {
	 *   Class superclass;          // Class = *objc_class
	 *   cache_t cache;
	 *   class_data_bits_t bits;    // class_rw_t * plus custom rr/alloc flags
	 * }
	 *
	 *  objc_class (4*5 byte)
	 * +-------------------------+
	 * | isa                     | 4byte
	 * +-------------------------+
	 * | superclass              |
	 * +-------------------------+
	 * | c._buckets              |---> first bucket
	 * +-----------+-------------+
	 * | c._mask   | c._occupied |
	 * +-----------+-------------+
	 * | bits                    |
	 * +-------------------------+
	 * 
	 * 
	 *                             <--+
	 *                                |
	 * bucket_t * cache_size          |
	 * +-------------------------+    |
	 * | key                     |    |
	 * +-------------------------+    |
	 * | imp                     |    |
	 * +-------------------------+    |
	 * | key                     |    |
	 * +-------------------------+    |
	 * | imp                     |    |
	 * +-------------------------+    |
	 * | key                     |    |
	 * +-------------------------+    |
	 * | imp                     |    |
	 * +-------------------------+    |
	 * | key = 1                 |    |
	 * +-------------------------+    |
	 * | imp = &(key[0])-8       |----+
	 * +-------------------------+
	 *
	 *
	 *
	 */
	objc_msgSend: function(self /*objc_object*/, sel/*SEL*/, param1 /*...*/) {

		function call_imp(imp, args) {
			var sig = "i";
			for(var i = 0; i < args.length; i++) sig += "i";
			console.log("will call", imp, args);
			return Runtime.dynCall(sig, imp, args);
		}

		console.log("args", self, sel, param1);
		console.log("args.length="+arguments.length);	

		if(!self) return 0;

		var cls = HEAP32[(self+0)>>2]|0; // self->isa
		var mask = HEAP32[(cls+12)>>2]|0; // (cls->cache)._mask
		var bucket = HEAP32[(cls+8)>>2]|0; // (cls->cache)._buckets

		var index = sel & mask;
		var key;
		for(bucket += index*8; key != 0; bucket += 8) {
			key = HEAP32[bucket>>2]|0; // bucket->_key
			if(key == sel) {
				// cache hit
				console.log("cache hit");
				var imp = HEAP32[(bucket+4)>>2]|0;
				return call_imp(imp, arguments);
			} else if(key == 1) {
				// cache wrap
				console.log("cache wrap");
				bucket = HEAP32[(bucket+4)>>2]|0;
			}
		}
		// cache miss
		console.log("cache miss");
		var imp = __class_lookupMethodAndLoadCache3(self, sel, cls);
		return call_imp(imp, arguments);
	},
	_objc_msgForward: function() {
		throw "_objc_msgForward is unimplemented";
	},
	_objc_msgForward_impcache: function() {
		throw "_objc_msgForward_impcache is unimplemented";
	},
	_objc_msgSend_uncached_impcache: function() {
		throw "_objc_msgSend_uncached_impcache is unimplemented";
	},
	cache_getImp: function() {
		console.log("cache_getImp is not implemented. return NULL");
		return 0;
	},
	_objc_ignored_method: function() {
		throw "_objc_ignored_method is unimplemented";
	}
});

