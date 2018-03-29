require "02_ring_buffer"

describe RingBuffer do
  it "has a logical_idx_to_physical_idx method" do
    arr = RingBuffer.new(10)
    5.times { |i| arr.push(i) }

    (0...10).each do |logical_idx|
      physical_idx = arr.send(:logical_idx_to_physical_idx, logical_idx)
      expect(physical_idx).to eq(logical_idx)
    end
  end

  describe "#shift" do
    it "shift returns first item" do
      arr = RingBuffer.new(10)
      5.times { |i| arr.push(i) }

      expect(arr.shift).to eq(0)
    end

    it "shift changes start_idx and physical_idxs" do
      arr = RingBuffer.new(10)
      5.times { |i| arr.push(i) }
      arr.shift

      expect(arr.send(:start_idx)).to eq(1)

      (0...9).each do |logical_idx|
        physical_idx = arr.send(:logical_idx_to_physical_idx, logical_idx)
        expect(physical_idx).to eq(1 + logical_idx)
      end
    end

    it "when start_idx != 0 logical_idx_to_physical_idx handles wraparround" do
      arr = RingBuffer.new(10)
      5.times { |i| arr.push(i) }
      arr.shift

      expect(arr.send(:start_idx)).to eq(1)
      physical_idx = arr.send(:logical_idx_to_physical_idx, 9)
      expect(physical_idx).to eq(0)
    end

    it "repeated shifts work and change start_idx each time" do
      arr = RingBuffer.new(10)
      10.times { |i| arr.push(i) }
      10.times do |i|
        expect(arr.shift).to eq(i)
        expect(arr.send(:start_idx)).to eq((i + 1) % 10)
      end
    end

    it "repeated shifts decrease length" do
      arr = RingBuffer.new(10)
      5.times { |i| arr.push(i) }
      5.times do |i|
        arr.shift
        expect(arr.length).to eq(5 - (i + 1))
      end
    end

    it "shift when empty raises exception" do
      arr = RingBuffer.new(10)
      5.times { |i| arr.push(i) }
      5.times { arr.shift }

      expect do
        arr.shift
      end.to raise_error("RingBuffer: index out of bounds")
    end

    it "repeated shifts change logical index positions" do
      arr = RingBuffer.new(10)
      5.times { |i| arr.push(i) }
      5.times do |i|
        arr.shift

        (0...10).each do |logical_idx|
          physical_idx = arr.send(:logical_idx_to_physical_idx, logical_idx)
          expected_physical_idx = ((i + 1) + logical_idx) % 10
          expect(physical_idx).to eq(expected_physical_idx)
        end
      end
    end

    it "when start_idx != 0 #[] uses proper physical index" do
      arr = RingBuffer.new(10)
      10.times { |i| arr.push(i) }

      (1..10).each do |times_removed|
        arr.shift

        (0...(10 - times_removed)).each do |idx|
          expect(arr[idx]).to eq(times_removed + idx)
        end
      end
    end

    it "when start_idx != 0 #[]= uses proper physical index" do
      arr = RingBuffer.new(10)
      10.times { |i| arr.push(i) }

      (1..10).each do |times_removed|
        arr.shift

        (0...(10 - times_removed)).each do |idx|
          val = 2 ** idx
          arr[idx] = val
          expect(arr[idx]).to eq(val)
        end
      end
    end

    it "handles a series of shifts and pushes" do
      arr = RingBuffer.new(10)
      10.times { |i| arr.push(i) }

      10.upto(20) do |val|
        expect(arr.shift).to eq(val - 10)

        arr.push(val)

        expect(arr[9]).to eq(val)

        expected_physical_idx = (val - 10) % 10
        expect(arr.send(:logical_idx_to_physical_idx, 9)).to eq(expected_physical_idx)

        expect(arr.send(:store)[expected_physical_idx]).to eq(val)
      end
    end
  end

  it "has an unshift method" do
    arr = RingBuffer.new(10)
    10.times { |i| arr.unshift(i) }
    10.times { |i| expect(arr[i]).to eq(9 - i) }
  end

  it "unshift when full raises exception" do
    arr = RingBuffer.new(10)
    10.times { |i| arr.unshift(i) }

    expect do
      arr.unshift(10)
    end.to raise_error("ring buffer has no more space")
  end

  # TODO: finish last specs for unshift.
end