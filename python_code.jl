using PyCall

# Import the 3dbinpacking library
py3dbp = pyimport("py3dbp")

function call_3dbinpacking(containers, items)
    # Initialize the packer
    packer = py3dbp.Packer()

    # Add containers
    for container in containers
        packer.add_bin(py3dbp.Bin(container...))  # Spread container attributes
    end

    # Add items
    for item in items
        packer.add_item(py3dbp.Item(item...))  # Spread item attributes
    end

    # Perform the packing
    packer.pack()

    # Retrieve the results
    results = []
    for bin in packer.bins
        packed_volume = 0.0

        # Compute packed volume from items
        for item in bin.items
            # Convert dimensions from Decimal to Float64 for computation
            width = float(item.width)
            height = float(item.height)
            depth = float(item.depth)
            packed_volume += width * height * depth
        end

        bin_info = Dict(
            "container" => bin.string(),
            "packed_volume" => packed_volume,  # Computed packed volume
            "items" => [item.string() for item in bin.items]
        )
        push!(results, bin_info)
    end
    return results
end

# Example Data
containers = [
    ("Container1", 100, 100, 100, 1000)  # Name, Width, Height, Depth, Max Weight
]

items = [
    ("Item1", 50, 50, 50, 10),  # Name, Width, Height, Depth, Weight
    ("Item2", 70, 70, 70, 20),
    ("Item3", 30, 30, 30, 5)
]
