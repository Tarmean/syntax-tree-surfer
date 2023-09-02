return function(silent)
	for n, _ in pairs(package.loaded) do
		if n:match("^syntax.tree.surfer") then
			if not silent then
				print("unloading", n)
			end
			package.loaded[n] = nil
		end
	end
end
