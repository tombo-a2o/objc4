var lib = {
	$utils: {
		dump_str: function(p) {
			var ret = "";
			for(var ii = p; HEAP8[ii] != 0; ii++) {
				ret += String.fromCharCode(HEAP8[ii]);
			}
			return ret;
		},
		nishin: function(a) {
			console.log( "fedcba9876543210fedcba9876543210");
			console.log(("00000000000000000000000000000000"+(a>>>0).toString(2)).slice(-32));
		},
		dump_class: function(cls) {
			var bits = HEAP32[(cls+16)>>2]|0;
			console.log("cls, bits", cls, bits);
			utils.nishin(bits);
			var class_rw_flags = HEAP32[bits>>2]|0;
			var class_rw_version = HEAP32[(bits+4)>>2]|0;
			var class_rw_ro = HEAP32[(bits+8)>>2]|0;
			var method_list = HEAP32[(bits+12)>>2]|0;
			console.log("class_rw_flags");
			utils.nishin(class_rw_flags);
			utils.nishin(1<<20);
			console.log("class_rw_version", class_rw_version);
			console.log("class_rw_ro", class_rw_ro);
			console.log("class_rw_method_list", method_list);
			if(method_list) {
				var method_list_entsize = HEAP32[method_list >> 2];
				var method_list_count = HEAP32[method_list+4 >> 2];
				var method_list_first = method_list+8;
				console.log("entsize", method_list_entsize);
				console.log("count", method_list_count);
				console.log("first", method_list_first);
				for(var i = 0; i < method_list_count; i++) {
					var first_name = HEAP32[method_list_first>>2];
					var first_types = HEAP32[method_list_first+4>>2]
					var first_imp = HEAP32[method_list_first+8>>2]
					console.log(i+":name", utils.dump_str(first_name));
					console.log(i+":type", first_types);
					console.log(i+":imp", first_imp);
					method_list_first += 12;
				}
			}
			/*
			var class_ro_base_method = HEAP32[class_rw_ro+20 >> 2];
			console.log("base method", class_ro_base_method);
			var base_entsize = HEAP32[ class_ro_base_method >> 2];
			var base_count = HEAP32[ class_ro_base_method+4 >> 2];
			var base_first = HEAP32[ class_ro_base_method+8 >> 2];
			*/
		}
	},

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
	objc_msgSend: function(self /*objc_object*/, sel/*SEL*/ /*...*/) {

		function call_imp(imp, args) {
			//console.log("will call", imp, args);
			return Runtime.dynCall("o", imp, args);
		}

		//console.log("objc_msgSend begin:", arguments, utils.dump_str(sel));

		if(!self) {
			console.log("objc_msgSend nullpo");
			return 0;
		}

		var cls = HEAP32[(self+0)>>2]|0; // self->isa
		var mask = HEAP16[(cls+12)>>1]|0; // (cls->cache)._mask
		var bucket = HEAP32[(cls+8)>>2]|0; // (cls->cache)._buckets

//		utils.dump_class(cls);

		var index = sel & mask;
		var key;
		for(bucket += index*8; (key = HEAP32[bucket>>2]|0) != 0; bucket += 8) {
			if(key == sel) {
				// cache hit
				console.log("cache hit");
				var imp = HEAP32[(bucket+4)>>2]|0;
				var ret = call_imp(imp, arguments);
				//console.log("objc_msgSend begin:", arguments, utils.dump_str(sel));
				return ret;
			} else if(key == 1) {
				// cache wrap
				console.log("cache wrap");
				bucket = HEAP32[(bucket+4)>>2]|0;
			}
		}
		// cache miss
		//console.log("cache miss");
		var imp = __class_lookupMethodAndLoadCache3(self, sel, cls);
		//console.log("objc_msgSend __class_lookupMethodAndLoadCache3", imp);
		var ret = call_imp(imp, arguments);
		//console.log("objc_msgSend end:", arguments, utils.dump_str(sel), ret);
		return ret;
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
	cache_getImp: function(cls, sel) {
		//console.log("cache_getImp", cls, sel, utils.dump_str(sel));
		//return 0;

		var mask = HEAP16[(cls+12)>>1]|0; // (cls->cache)._mask
		var bucket = HEAP32[(cls+8)>>2]|0; // (cls->cache)._buckets

		var index = sel & mask;
		var key;
		for(bucket += index*8; (key = HEAP32[bucket>>2]|0) != 0; bucket += 8) {
			if(key == sel) {
				// cache hit
				console.log("cache hit");
				var imp = HEAP32[(bucket+4)>>2]|0;
				// TODO
				// if(imp == ___objc_msgSend_uncached_impcache) return 0;
				return imp;
			} else if(key == 1) {
				// cache wrap
				console.log("cache wrap");
				bucket = HEAP32[(bucket+4)>>2]|0;
			}
		}
		// cache miss
		// console.log("cache miss");
		return 0;
	},
	_objc_ignored_method: function() {
		throw "_objc_ignored_method is unimplemented";
	}
};
autoAddDeps(lib, '$utils');
mergeInto(LibraryManager.library, lib);
