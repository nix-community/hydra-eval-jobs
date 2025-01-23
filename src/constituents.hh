#pragma once

#include "fmt.hh"
#include <map>
#include <nlohmann/json_fwd.hpp>
#include <set>
#include <string>
#include <utility>
#include <variant>

#include <nix/config.h>
#include <nix/store-api.hh>

struct DependencyCycle : public std::exception {
    std::string a;
    std::string b;
    std::set<std::string> remainingAggregates;

    DependencyCycle(std::string a, std::string b,
                    const std::set<std::string> &remainingAggregates)
        : a(std::move(a)), b(std::move(b)),
          remainingAggregates(remainingAggregates) {}

    [[nodiscard]] auto message() const -> std::string {
        return nix::fmt("Dependency cycle: %s <-> %s", a, b);
    }
};

struct AggregateJob {
    std::string name;
    std::set<std::string> dependencies;
    std::unordered_map<std::string, std::string> brokenJobs;

    auto operator<(const AggregateJob &b) const -> bool {
        return name < b.name;
    }
};

auto resolveNamedConstituents(const std::map<std::string, nlohmann::json> &jobs)
    -> std::variant<std::vector<AggregateJob>, DependencyCycle>;

void rewriteAggregates(std::map<std::string, nlohmann::json> &jobs,
                       const std::vector<AggregateJob> &aggregateJobs,
                       nix::ref<nix::Store> &store, nix::Path &gcRootsDir);
